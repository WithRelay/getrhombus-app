class User < ActiveRecord::Base

  include DashboardMerchantQueries
  include DashboardCustomerQueries
  include CSVHandler

  attr_accessor :phone, :captured_amt, :msg_id, :tag_id, :referrer_id

  # include default devise modules. Others available are: :token_authenticatable, :lockable, :timeoutable and :confirmable,
  devise :database_authenticatable, :registerable, :recoverable, :rememberable, :trackable, :validatable, :omniauthable

  has_many :transactions
  has_many :team_transactions, class_name: 'Transaction', foreign_key: 'team_id'

  has_many :subscriptions
  has_many :team_subscriptions, class_name: 'Subscription', foreign_key: 'team_id'

  has_many :referrers, class_name: 'Referrer', foreign_key: 'referrer_id'
  has_many :referees, class_name: 'Referrer', foreign_key: 'referee_id'

  has_many :campaigns
  has_many :hashtags

  has_many :messages
  has_many :team_conversations, class_name: 'Conversation', foreign_key: 'merchant_id'

  has_many :plans
  has_many :coupons

  has_one :twitter_cred
  has_one :fb_cred

  has_one :alert, dependent: :destroy
  has_many :fb_pages
  
  has_many :saved_replies
  has_many :message_resolutions

  has_many :image_refs, as: :imageable
  has_many :images, through: :image_refs

  # A user can have belong to more than one list and also own multiple lists (Admins)
  has_many :lists
  has_many :user_lists

  has_many :bank_accounts
  accepts_nested_attributes_for :bank_accounts

  has_many :stripe_cred
  accepts_nested_attributes_for :stripe_cred

  has_one :address, as: :addressable
  accepts_nested_attributes_for :address

  has_many :people
  accepts_nested_attributes_for :people, allow_destroy: true  # reject_if: ->(attrs) { attrs['city'].blank? || attrs['street'].blank? }

  before_validation :the_titleizer
  before_create :set_merchant_org_phone          # only create because the actual org_phone field is used in edit view

  after_commit :create_user_alert, on: :create, if: lambda { self.user_level == 1 }
  after_commit :update_phone_in_db, on: :update

  validates_presence_of :user_level, message: "Please select an account type"
  # Sign up form uses phone_number field for both user types
  validates_presence_of :phone_number, numericality: { only_integer: true }, length: { minimum: 10 }, on: :create

  # Edit pages use the right number field for each user type
  validates_presence_of :org_number, numericality: { only_integer: true }, length: { minimum: 10 }, on: :update, if: lambda { self.user_level == 1 }
  validates_presence_of :phone_number, numericality: { only_integer: true }, length: { minimum: 10 }, on: :update, if: lambda { self.user_level == 0 }

  # Allow nil added to db migration because merchants don't have phone number. They have org_phone.
  # And since mysql indexes this field, it indexes nil and only allows one row with nil.
  # You run into issues with any additional merchants.
  validates_uniqueness_of :phone_number, :allow_nil => true, :if => lambda { self.user_level == 0 }
  validate :phone_number_cannot_be_rhombus_number
 
  def is_merchant?
    user_level == 1
  end

  def is_platform?
    email != '<redacted_email>' && email != '<redacted_email>'
  end

  def can_send_mms?
    ['US', 'CA'].include? self.country
  end

  # Create or update customer on Stripe
  # move to stripe service
  def add_token_to_stripe_customer(params)
    if params[:card_token].present?  # is this why i get the errors from stripe??
      begin
        if self.customer_uri.blank?   # Doesnt have a customer uri => first time
          cu = Stripe::Customer.create(email: self.email, source: params[:card_token])
          self.customer_uri = cu.id
          self.livemode = cu.livemode
        else
          cu = Stripe::Customer.retrieve(self.customer_uri)
          cu.email = self.email
          cu.source = params[:card_token]
          cu.save
        end
        buy_merchant_number if self.user_level == 1 && self.rn_type == nil
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
      false
    end
    true
  end

  def buy_merchant_number
    # save the area code in rhombus number till a number is bought
    #number = TextingService.buy_number(self.rhombus_number])
    #self.rn_type = number if number
    self.rhombus_number = number if number
    return number[0]
    # if successful create bitly link
    # @user.short_url = UrlShortenerService.shorten_link("https://www.getrhombus.com/signup?referrer_id=#{@user.id}")
  end

  # Returns hash with users who sent a message to the given merchant in the last "num_days" days
  def self.get_latest_active_messaging(merchant_id, num_days)
    # name is now thrugh person
    users = Message.select('`users`.`id`, `users`.`first_name`, `users`.`last_name`, `users`.`email`, `messages`.`from`')
                   .joins('LEFT JOIN `users` ON (`users`.`id` = `messages`.`user_id`)')
                   .where('(`messages`.`user_id_to` = ? AND `messages`.`created_at` >= ?) OR (`messages`.`user_id_to` = ? AND `messages`.`unread` = ?)', merchant_id, Time.current - num_days.days, merchant_id, true)
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

  def phone
    self.user_level == 0 ? self.phone_number : self.org_phone
  end

  private

    # Some users sign up with Rhombus numbers
    def phone_number_cannot_be_rhombus_number
      if User.exists?(rhombus_number: self.phone_number)
        errors.add(:phone_number, "can't be a Rhombus number. Please enter your phone number.")
      end
    end

    def set_merchant_org_phone
      if self.user_level == 1
        self.org_phone = self.phone_number
        self.phone_number = nil
      end
    end

    def the_titleizer
      self.card_name = self.card_name.strip.titleize unless self.card_name.blank?
      self.url = self.url.strip unless self.url.blank?
      self.custom_welcome = self.custom_welcome.strip unless self.custom_welcome.blank?
      self.org_name = self.org_name.strip unless self.org_name.blank?
    end

    def send_welcome_email
      owner = User.find_by(email: Rails.application.secrets.team_email)
      if self.user_level == 1
        EmailingService.send_welcome_email(self.email, owner.rhombus_number, "merchant")
      elsif self.user_level == 0
        ref = self.referrers.first
        unless ref.blank?
          referrer = User.find_by(id: ref.referrer_id)
          EmailingService.send_welcome_email_with_referral(ref.email, self.email, ref.org_name, ref.rhombus_number, owner.rhombus_number)
          text = "Thanks for signing up! Please add a payment card to your Rhombus profile (if you haven't done so).
          You can chat with us anytime via sms or to make a payment, just text the amount & description/hashtag. Ex. +10 #donut"
          Message.send_and_save_message(ref.rhombus_number, self.phone_number, text)
        else
          EmailingService.send_welcome_email(self.email, owner.rhombus_number, "customer")
          text = "Thanks for signing up! Please add a payment card to your Rhombus profile (if you haven't done so).
          You can chat with a local business anytime by texting their Rhombus number or to make a payment, just text the amount &
          description/hashtag. Ex. +10 #donut"
          Message.send_and_save_message(owner.rhombus_number, self.phone_number, text)
        end
      end
    end

    # move to background job
    def update_phone_in_db
      if self.user_level == 0
        if x = self.previous_changes['phone_number']
          ActiveRecord::Base.connection.execute("UPDATE messages SET messages.from = #{x[1]} WHERE messages.from = #{x[0]}")
          ActiveRecord::Base.connection.execute("UPDATE messages SET messages.to = #{x[1]} WHERE messages.to = #{x[0]}")
        end
      end
    end

    def create_user_alert
      Alert.create_with(user_id: self.id, sms_number: self.org_phone).find_or_create_by(user_id: self.id)
    end

end

=begin

def add_token_to_stripe_customer(params)
    if params[:card_token].present?  # is this why i get the errors from stripe??
      begin
        hash = { email: self.email, card_token: params[:card_token] }
        if self.customer_uri.blank?   # Doesnt have a customer uri => first time
          res = PaymentService.create_customer(hash)
          if res[0]
            self.customer_uri = cu.id
            self.livemode = cu.livemode
          end
        else
          hash[:uri] = self.customer_uri
          PaymentService.update_customer(hash)
        end

        buy_merchant_number if self.user_level == 1 && self.rn_type == nil

        # move out this exception block
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
      false
    end
    true
  end
=end
