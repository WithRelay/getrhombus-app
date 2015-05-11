class User < ActiveRecord::Base

  include DashboardQueries
  Stripe.api_key = Rails.application.secrets.stripe["secret_key"]

  attr_accessor :full_name, :phone
  # Include default devise modules. Others available are:
    # :token_authenticatable, :lockable, :timeoutable and :confirmable,
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable
  devise :omniauthable, :omniauth_providers => [:stripe_connect]

  #has_many :messages, dependent: :destroy
  has_many :transactions, dependent: :destroy

  before_validation :get_only_numbers, :the_titleizer
  # only create, cos they can change this in edit
  before_create :set_merchant_business_phone, :deactivate_merchant_account          

  after_commit :send_welcome_email, :on => :create

  validates_presence_of :user_level, :message => "Please select an account type"
  
  # still need validation errors for edit..this is only for create action
  validates :phone_number, presence: true, 
            numericality: { only_integer: true }, 
            length: { minimum: 10 }, 
            :on => :create

  validates_uniqueness_of :phone_number, :allow_nil => true, :if => lambda { self.user_level == 0 }
  # Switch this on when rhombus numbers are automatically generated
  # validates_uniqueness_of :rhombus_number, :allow_nil => true, :if => lambda { self.user_level == 1 } 

  # saves merchant info from stripe
  def from_omniauth(auth)
    self.provider = auth.provider
    self.uid = auth.uid
    self.stripe_access_token = auth.credentials.token
    self.stripe_publishable_key = auth.info.stripe_publishable_key
    self.stripe_scope = auth.info.scope
    self.stripe_livemode = auth.info.livemode
    if self.save
      return true
    else
      return false
    end
  end

  # Create or update customer on Stripe
  def add_token_to_stripe_customer(params)
    if self.user_level == 0 && params[:instrument_uri].present?   # is this why i get the errors from stripe??
      begin 
        if self.customer_uri.blank?                                     # Doesnt have a customer uri => first time
          response = Stripe::Customer.create(:email => "#{self.email}", :card => params[:instrument_uri])         
          self.customer_uri = response.id
          self.stripe_livemode = response.livemode
          self.save
        else
          response = Stripe::Customer.retrieve(self.customer_uri)  
          response.email = self.email
          response.card = params[:instrument_uri]
          response.save   
        end
      rescue Stripe::CardError => e
        # Since it's a decline, Stripe::CardError will be caught
        body = e.json_body
        err  = body[:error]

        #owner = User.find_by(email: '<redacted_email>')                   # for development
        owner = User.find_by(email: '<redacted_email>')                # for production

        @message = Message.new
        @message.send_and_save_message(18, owner.rhombus_number, self.phone_number, 
              "We were unable to update your card info on Rhombus because: #{err[:message]}.")

        Notification.token_failure_notification(err, self.email).deliver_now
        return false
      rescue Stripe::StripeError => e
        body = e.json_body
        err  = body[:error]
        Notification.token_failure_notification(err, self.email).deliver_now
        return false
      rescue StandardError => e
        Notification.token_failure_notification(e, self.email).deliver_now
        return false
      else
        return true                # yep!! we gat this
      end      
    end
    return true                     # Not a customer just a merchant
  end
 
  # Returns hash with users who sent a message to the given merchant in the last "num_days" days
  def self.get_latest_active_messaging(merchant_id, num_days)
    users = Message.select('`users`.`id`, `users`.`first_name`, `users`.`last_name`, `users`.`email`')
                   .joins('INNER JOIN `users` ON (`users`.`id` = `messages`.`user_id_from`)')
                   .where('(`messages`.`user_id_to` = ? AND `messages`.`created_at` >= ?) OR (`messages`.`user_id_to` = ? AND `messages`.`unread` = ?)', merchant_id, Time.zone.now - num_days.days, merchant_id, true)
                   .group('`messages`.`user_id_from`')
    latest_active = Array.new
    users.each do |user|
      last_message = Message.select('text, created_at').where('user_id_from = ? AND user_id_to = ?', user.id, merchant_id).order('created_at DESC').limit(1).first
      latest_active.push({
        :id => user.id,
        :first_name => user.first_name,
        :last_name => user.last_name,
        :email => user.email,
        :image_url => ActionController::Base.helpers.asset_path('user_icon_50x50.png'),
        :last_message => last_message.blank? ? '' : last_message.text,
        :last_message_ts => last_message.blank? ? 0 : last_message.created_at.to_i,
        :unread_count => Message.where('user_id_from = ? AND user_id_to = ? AND unread = ?', user.id, merchant_id, true).count
      })
    end
    latest_active
  end

  def full_name
    if self.user_level == 0
      x = (self.first_name) ? self.first_name : ''
      y = (self.last_name) ? self.last_name : ''
      return nil if (x + y) == ""
      x + " " + y
    end
  end
  
  def phone
    return self.phone_number if self.user_level == 0
    self.business_phone
  end

  private

  def get_only_numbers
    self.phone_number = self.phone_number.gsub(/\D/, "") unless self.phone_number.blank?
    self.business_phone = self.business_phone.gsub(/\D/, "") unless self.business_phone.blank?
  end

  # this is to automate assigning rhombus numbers
  def set_rhombus_number
    if self.user_level == 1
      self.rhombus_number = TextingService.buy_number("US")
      self.save
    end
  end

  def set_merchant_business_phone
    # If a merchant is signing up, make business number the phone number. Would be useful when merchants can become regular users and vice versa
    if self.user_level == 1
      self.business_phone = self.phone_number
      self.phone_number = nil
    end 
  end

  def deactivate_merchant_account
      if self.user_level == 1
          self.is_active = 0
      end 
  end

  def the_titleizer       #remove leading and trailing whitespaces
    self.first_name = self.first_name.strip.titleize unless self.first_name.blank?
    self.last_name = self.last_name.strip.titleize unless self.last_name.blank?
    self.card_name = self.card_name.strip.titleize unless self.card_name.blank?

    self.street_address = self.street_address.strip unless self.street_address.blank?
    self.city = self.city.strip.titleize unless self.city.blank?
    self.state_province = self.state_province.strip.upcase unless self.state_province.blank?
    
    self.url = self.url.strip unless self.url.blank?
    self.custom_welcome = self.custom_welcome.strip unless self.custom_welcome.blank?
    self.referrer_num = self.referrer_num.strip unless self.referrer_num.blank?
    self.business_name = self.business_name.strip unless self.business_name.blank?
  end

  def send_welcome_email
    owner = User.find_by(email: '<redacted_email>')
    if self.user_level == 1
      EmailingService.send_welcome_email(self.email, owner.rhombus_number, "merchant")
    elsif self.user_level == 0
      @message = Message.new
      unless self.referrer_num.blank?
        referrer = User.find_by(rhombus_number: self.referrer_num)
        EmailingService.send_welcome_email_with_referral(referrer.email, self.email, referrer.business_name, referrer.rhombus_number, owner.rhombus_number)
        # default for referrer or use merchant welcome
        text = "Hi there, my name is #{referrer.first_name}, how can I assist you today? If you're looking to send a payment, simply reply with the amount."
        text = referrer.custom_welcome unless referrer.custom_welcome.blank?
        @message.send_and_save_message(22, referrer.rhombus_number, self.phone_number, text)
        return
      end
      EmailingService.send_welcome_email(self.email, owner.rhombus_number, "customer")
      text = "Hi there, thanks for signing up with Rhombus. You can now chat with or pay your favorite merchants."
      @message.send_and_save_message(22, owner.rhombus_number, self.phone_number, text)
    end
  end
  
end
