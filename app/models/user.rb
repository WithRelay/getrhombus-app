class User < ActiveRecord::Base

  include DashboardQueries
  include CSVHandler

  attr_accessor :full_name, :phone, :captured_amt, :msg_id, :tag_id,
                # used to identify what type of action in user's controller update action
                :update_rhombus_number  
  
  # include default devise modules. Others available are:
  # :token_authenticatable, :lockable, :timeoutable and :confirmable,
  devise :database_authenticatable, :registerable, :recoverable, :rememberable, :trackable, :validatable, :omniauthable

  has_many :messages, dependent: :destroy
  has_many :transactions, dependent: :destroy
  has_many :hashtags, dependent: :destroy
  has_one :twitter_cred, dependent: :destroy
  has_many :image_refs, as: :imageable, dependent: :destroy
  has_many :images, through: :image_refs, dependent: :destroy

  before_validation :get_only_numbers, :the_titleizer
  
  # only create, cos they can change this in edit

  # remove this soon
  before_create :set_merchant_business_phone, :deactivate_merchant_account          

  # Just to prevent sending emails locally for now...remove comment later
  # after_commit :send_welcome_email, :on => :create

  validates_presence_of :user_level, :message => "Please select an account type"
  validates :country, length: {is: 2}, allow_blank: true
  
  # why allow nil?
  validates_uniqueness_of :phone_number, :allow_nil => true, :if => lambda { self.user_level == 0 }

  # still need validation errors for edit..this is only for create action
  validates :phone_number, presence: true, numericality: { only_integer: true }, length: { minimum: 10 }, on: :create


  # saves merchant info from stripe
  def save_stripe_omniauth_data(auth)
    self.provider = auth.provider
    self.uid = auth.uid
    self.stripe_access_token = auth.credentials.token
    self.stripe_publishable_key = auth.info.stripe_publishable_key
    self.stripe_scope = auth.info.scope
    self.stripe_livemode = auth.info.livemode
    return true if self.save
    return false
  end

  # Create or update customer on Stripe
  def add_token_to_stripe_customer(params)
    #return false
    if self.user_level == 0 && params[:instrument_uri].present?  # is this why i get the errors from stripe??
      begin 
        if self.customer_uri.blank?                                     # Doesnt have a customer uri => first time
          cu = Stripe::Customer.create(email: self.email, source: params[:instrument_uri])         
          self.customer_uri = cu.id
          self.stripe_livemode = cu.livemode
        else
          cu = Stripe::Customer.retrieve(self.customer_uri)  
          cu.email = self.email
          cu.source = params[:instrument_uri]
          cu.save   
        end
      rescue Stripe::CardError => e
        # Since it's a decline, Stripe::CardError will be caught
        body = e.json_body
        err  = body[:error]

        owner = User.find_by(email: Rails.application.secrets.team_email)
        Message.send_and_save_message(owner.rhombus_number, self.phone_number, "We were unable to update your card info on Rhombus because: #{err[:message]}.")
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
    users = Message.select('`users`.`id`, `users`.`first_name`, `users`.`last_name`, `users`.`email`, `messages`.`from`')
                   .joins('LEFT JOIN `users` ON (`users`.`id` = `messages`.`user_id`)')
                   .where('(`messages`.`user_id_to` = ? AND `messages`.`created_at` >= ?) OR (`messages`.`user_id_to` = ? AND `messages`.`unread` = ?)', merchant_id, Time.zone.now - num_days.days, merchant_id, true)
                   .group('`messages`.`from`')
    latest_active = Array.new
    users.each do |user|
      last_message = user.id.blank? ? Message.select('text, created_at').where('`from` = ? AND `user_id_to` = ?', user.from, merchant_id).order('created_at DESC').limit(1).first : Message.select('text, created_at').where('user_id = ? AND user_id_to = ?', user.id, merchant_id).order('created_at DESC').limit(1).first
      latest_active.push({
        :user_number => user.from,
        :first_name => user.first_name.blank? ? user.from : user.first_name,
        :last_name => user.last_name.blank? ? '' : user.last_name,
        :email => user.email.blank? ? '' : user.email,
        :profile_image => ActionController::Base.helpers.asset_path('user_icon_50x50.png'),
        :last_message => last_message.blank? ? '' : last_message.text,
        :last_message_ts => last_message.blank? ? 0 : last_message.created_at.to_i,
        :unread_count =>  user.id.blank? ? Message.where('`from` = ? AND `user_id_to` = ? AND `unread` = ?', user.from, merchant_id, true).count : Message.where('user_id = ? AND user_id_to = ? AND unread = ?', user.id, merchant_id, true).count
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

  def update_merchant_account(params)
    if params.key? :update_rhombus_number
      #number = TextingService.buy_number(params[:rhombus_number])
      #return false if !number
      self.rhombus_number = number
    end
    return true
  end

  private

  # can reduce all these self calls here ###############


  def get_only_numbers
    self.phone_number = self.phone_number.gsub(/\D/, "") unless self.phone_number.blank?
    self.business_phone = self.business_phone.gsub(/\D/, "") unless self.business_phone.blank?
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
    owner = User.find_by(email: Rails.application.secrets.team_email)
    if self.user_level == 1
      EmailingService.send_welcome_email(self.email, owner.rhombus_number, "merchant")
    elsif self.user_level == 0
      message = Message.new
      unless self.referrer_num.blank?
        referrer = User.find_by(rhombus_number: self.referrer_num)
        EmailingService.send_welcome_email_with_referral(referrer.email, self.email, referrer.business_name, referrer.rhombus_number, owner.rhombus_number)
        text = "Thanks for signing up! Please add a payment card to your Rhombus profile (if you haven't done so). 
        You can chat with us anytime via sms or to make a payment, just text the amount & description/hashtag. Ex. +10 #donut"
        message.send_and_save_message(referrer.rhombus_number, self.phone_number, text)
        return
      end
      EmailingService.send_welcome_email(self.email, owner.rhombus_number, "customer")
      text = "Thanks for signing up! Please add a payment card to your Rhombus profile (if you haven't done so). 
      You can chat with a local business anytime by texting their Rhombus number or to make a payment, just text the amount & 
      description/hashtag. Ex. +10 #donut"
      message.send_and_save_message(owner.rhombus_number, self.phone_number, text)
    end
  end
  
end
