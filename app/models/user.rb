class User < ActiveRecord::Base

  include DashboardMerchantQueries
  include DashboardCustomerQueries
  include CSVHandler

  attr_accessor :full_name, :phone, :captured_amt, :msg_id, :tag_id

  # include default devise modules. Others available are:
  # :token_authenticatable, :lockable, :timeoutable and :confirmable,
  devise :database_authenticatable, :registerable, :recoverable, :rememberable, :trackable, :validatable, :omniauthable

  has_many :transactions, dependent: :destroy
  has_many :team_transactions, class_name: 'Transaction', foreign_key: 'team_id'
  
  has_many :subscriptions, dependent: :destroy
  has_many :team_subscriptions, class_name: 'Subscription', foreign_key: 'team_id'

  # this goes away with conversation model
  has_many :messages, dependent: :destroy
  
  has_many :hashtags, dependent: :destroy
  has_one :twitter_cred, dependent: :destroy
  has_one :alert, dependent: :destroy

  has_many :image_refs, as: :imageable, dependent: :destroy
  has_many :images, through: :image_refs

  before_validation :the_titleizer
  
  # only create because the actual org_phone field is used in edit view
  before_create :set_merchant_org_phone          

  # Just to prevent sending emails locally for now...remove comment later
  # after_commit :send_welcome_email, on: :create
  after_commit :create_user_alert, on: :create, if: lambda { self.user_level == 1 }
  after_commit :update_phone_in_db, on: :update, if: lambda { self.previous_changes['phone_number'] && self.user_level == 0 }

  #validates_presence_of :user_level, :message => "Please select an account type"
  #validates :country, length: {is: 2}, allow_blank: true  
  # why allow nil?
  #validates_uniqueness_of :phone_number, :allow_nil => true, :if => lambda { self.user_level == 0 }
  # still need validation errors for edit..this is only for create action
  #validates :phone_number, presence: true, numericality: { only_integer: true }, length: { minimum: 10 }, on: :create

  # A user can have belong to more than one list and also own multiple lists (Admins)
  has_many :lists
  has_many :customers, through: :customer_lists

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
    if params[:instrument_uri].present?  # is this why i get the errors from stripe??
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
        buy_merchant_number if self.user_level == 1 && self.rhombus_number_type == nil
        return true
      rescue Stripe::CardError => e
        # Since it's a decline, Stripe::CardError will be caught
        err  = e.json_body[:error]
        owner = User.find_by(email: Rails.application.secrets.team_email)
        Message.send_and_save_message(owner.rhombus_number, self.phone_number, "We were unable to update your card info on Rhombus because: #{err[:message]}.")
        Notification.token_failure_notification(err, self.email).deliver_now
      rescue Stripe::StripeError => e
        Notification.token_failure_notification(e.json_body[:error], self.email).deliver_now
      rescue StandardError => e
        Notification.token_failure_notification(e, self.email).deliver_now
      end
    end

    return false
  end
 
  def buy_merchant_number
    # save the area code in rhombus number till a number is bought
    #number = TextingService.buy_number(self.rhombus_number])
    #self.rhombus_number_type = number if number
    self.rhombus_number = number if number
    return number[0]
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
      (x + y) == "" ? nil : x + " " + y
    end
  end
  
  def phone
    self.user_level == 0 ? self.phone_number : self.org_phone
  end

  def can_send_mms?
    ['US', 'CA'].include? self.country
  end

  private

  def set_merchant_org_phone
    if self.user_level == 1
      self.org_phone = self.phone_number
      self.phone_number = nil
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
    self.org_name = self.org_name.strip unless self.org_name.blank?
  end

  def send_welcome_email
    owner = User.find_by(email: Rails.application.secrets.team_email)
    if self.user_level == 1
      EmailingService.send_welcome_email(self.email, owner.rhombus_number, "merchant")
    elsif self.user_level == 0
      message = Message.new
      unless self.referrer_num.blank?
        referrer = User.find_by(rhombus_number: self.referrer_num)
        EmailingService.send_welcome_email_with_referral(referrer.email, self.email, referrer.org_name, referrer.rhombus_number, owner.rhombus_number)
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

  def update_phone_in_db
    # move to background job
    ActiveRecord::Base.connection.execute("UPDATE messages SET messages.from = #{x[1]} WHERE messages.from = #{x[0]}")
    ActiveRecord::Base.connection.execute("UPDATE messages SET messages.to = #{x[1]} WHERE messages.to = #{x[0]}")
  end

  def create_user_alert
    # move to background job?
    Alert.create(user_id: self.id, sms_number: self.org_phone)
  end
  
end
