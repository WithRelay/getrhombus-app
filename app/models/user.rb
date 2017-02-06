class User < ActiveRecord::Base

  include DashboardMerchantQueries
  include DashboardCustomerQueries
  include CSVHandler

  attr_accessor :phone, :captured_amt, :msg_id, :tag_id, :referrer_id, :tos_acceptance
  
  # validation rules for user attributes
  validates :tos_acceptance, acceptance: true, if: lambda { self.is_merchant? }, on: :update
  validates_presence_of :org_type, if: lambda { self.is_merchant? }, on: :update
  # validates_presence_of :org_name, if: lambda { self.is_merchant? && self.org_type.downcase != 'individual' }, on: :update
  
  # Edit pages use the right number field for each user type
  validates_presence_of :org_phone, numericality: { only_integer: true }, length: { minimum: 10 }, on: :update, if: lambda { self.is_merchant? }
  validates_presence_of :phone_number, numericality: { only_integer: true }, length: { minimum: 10 }, on: :update, if: lambda { self.is_customer? }
  validates_presence_of :user_level, message: "Please select an account type"
  
  # Sign up form uses phone_number field for both user types
  validates_presence_of :phone_number, numericality: { only_integer: true }, length: { minimum: 10 }, on: :create
  
  # Allow nil added to db migration because merchants don't have phone number. They have org_phone.
  # And since mysql indexes this field, it indexes nil and only allows one row with nil.
  # You run into issues with any additional merchants.
  validates_uniqueness_of :phone_number, :allow_nil => true, :if => lambda { is_merchant? }
  validate :phone_number_cannot_be_rhombus_number
  
  # include default devise modules. Others available are: :token_authenticatable, :lockable, :timeoutable and :confirmable,
  devise :database_authenticatable, :registerable, :recoverable, :rememberable, :trackable, :validatable, :omniauthable, :omniauth_providers => [:facebook, :twitter, :stripe_connect]

  has_many :transactions
  has_many :merchant_transactions, class_name: 'Transaction', foreign_key: 'team_id'

  has_many :subscriptions

  has_many :referrers, class_name: 'Referrer', foreign_key: 'referee_id'
  has_many :referees, class_name: 'Referrer', foreign_key: 'referrer_id'

  has_many :merchants, class_name: 'MerchantCustomer', foreign_key: 'customer_id'
  has_many :customers, class_name: 'MerchantCustomer', foreign_key: 'merchant_id'

  has_many :merchant, class_name: 'MerchantContact', foreign_key: 'merchant_id'

  has_many :reminders, -> { where campaign_type: 1 }
  # this block is for customizing build method for user.campaign which allow also to save list
  has_many :campaigns, -> { where campaign_type: 0 } do
    # overiding association build function like user.campaigns.build will hit here
    def build(*args)
      # calls parent build action and send arguments first from the splat operator
      campaign = super(args[0])
      unless args.blank?
        # build campaign lists of campaign
        args[0][:list_name].split(',').each{ |l| campaign.campaign_lists.build(list_id: l) } if args[0][:list_name].present?
        # build avatar of campaigns
        if args[1].present?
          campaign.images.build(avatar: args[1][:avatar], uploaded_as: 1) if (!campaign.sms? && args[1][:avatar].present?) && campaign.valid?
        # build image refs for inline images of campaigns
          args[1][:image_id].each do |avatar_id|
            campaign.image_refs.build(image_id: avatar_id).save;
          end if args[1][:image_id].present?
        end
      end
      return campaign
    end
  end

  has_many :hashtags

  has_many :messages
  has_many :merchant_conversations, class_name: 'Conversation', foreign_key: 'merchant_id'

  has_many :merchant_plans, class_name: 'Plan', foreign_key: 'merchant_id'
  has_many :customer_plans, class_name: 'Plan', foreign_key: 'customer_id'
  has_many :next_plans
  has_many :coupons

  has_one :twitter_cred
  has_many :fb_creds

  has_one :alert, dependent: :destroy
  has_many :fb_pages,dependent: :destroy

  has_many :saved_replies
  has_many :message_resolutions

  has_many :image_refs, as: :imageable
  has_many :images, through: :image_refs

  # A user can have belong to more than one list and also own multiple lists (Admins)
  has_many :lists
  has_many :user_lists

  has_many :bank_accounts
  accepts_nested_attributes_for :bank_accounts
  validates_associated :bank_accounts

  has_many :stripe_creds
  accepts_nested_attributes_for :stripe_creds

  has_one :address, as: :addressable
  accepts_nested_attributes_for :address
  validates_associated :address

  has_many :people
  accepts_nested_attributes_for :people, allow_destroy: true  # reject_if: ->(attrs) { attrs['city'].blank? || attrs['street'].blank? }

  before_validation :the_titleizer
  before_create :set_merchant_org_phone          # only create because the actual org_phone field is used in edit view

  after_commit :create_user_alert, on: :create, if: lambda { is_merchant? }
  after_commit :update_phone_in_db, on: :update

  def is_merchant?
    user_level == 1
  end

  def is_customer?
    user_level == 0
  end

  def is_platform?
    #email == User.platform_email
    self.email == '<redacted_email>' || self.email == '<redacted_email>'
  end

  def can_accept_payments?
    # the last stripe_cred is either a managed acct, a managed acct even if a user had a standalone acct, or a standalone acct
    creds = self.stripe_creds.last
    creds.present? ? creds.charges_enabled && creds.disabled_reason.blank? : false
  end

  def self.platform_email
    Rails.application.secrets.dashboard_email
  end

  def self.get_platform_acct_obj
    # you can change this temporarily to <redacted_email> or <redacted_email>
    # User.find_by(email: User.platform_email)
    User.find_by(email: "<redacted_email>") || User.find_by(email: "<redacted_email>")
  end

  def get_stripe_cred
    # platform acct is a standalone account and only one record exists for platform
    # merchants could have 2 records. Managed, Standalone (prior to v1.5)
    return self.stripe_creds.first if is_platform? 
    creds = self.stripe_creds
    creds.where(uid_type: ((creds.length == 2) ? 'managed' : 'standalone') ).first
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

  # remove this method
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
    is_customer? ? phone_number : org_phone
  end

  def add_token_to_user(card_token)
    begin
      # platform acct shouldn't really be doing this since it is just a management account
      unless is_platform?
        res = []
        platform_acct = User.get_platform_acct_obj

        # Two scenarios
        # 1. a merchant user who is a customer of platform
        # 2. a customer user who is a customer of the platform and/or merchant(s)
        # Note that a customer user becomes a customer of merchant when a subscription is created
        cu = MerchantCustomer.where(customer_id: self.id)
        hash = { email: self.email, card_token: card_token, is_new_customer: true, is_platform_customer: true, is_merchant: is_merchant? }

        # when blank, add only to platform. Blank indicates signing up
        if cu.blank?
          re = PaymentService.add_token_to_stripe_customer(hash)
          #buy_merchant_number if hash[:is_merchant] && rn_type == nil
        else
          hash[:is_new_customer] = false
          if hash[:is_merchant]
            hash[:stripe_customer_id] = cu.first.stripe_customer_id
            # is merchant, so update on platform
            re = PaymentService.add_token_to_stripe_customer(hash)
          else
            cu.each do |c|
              hash[:stripe_customer_id] = c.stripe_customer_id
              # can be on platform or merchant (stripe managed) account
              hash[:is_platform_customer] = c.merchant_id == platform_acct.id
              if hash[:is_platform_customer]
                re = PaymentService.add_token_to_stripe_customer(hash)
              else
                re = PaymentService.add_token_to_stripe_customer(hash, get_stripe_cred.uid)
              end
            end
          end
        end
        # create new merchant_customer for stripe customer
        if re.first
          if cu.blank?
            MerchantCustomer.create(merchant_id: platform_acct.id, customer_id: self.id, stripe_customer_id: re[1].id)
          end
        else
          # since new customer are always platform customer so is_platform is always true
          PaymentService.delete_customer(re[1].id, get_stripe_cred.uid, true) if cu.blank?
        end
      end
      re
    rescue StandardError => e
      # since new customer are always platform customer so is_platform is always true
      PaymentService.delete_customer(re[1].id, get_stripe_cred.uid, true) if (res.length > 0 && cu.blank?)
      # notify team
      [false]
    end
  end

  def self.check_profile_picture(cus)
    return { type: 'color', value: COLORS.first.first } if cus.nil?
    
    user_fb_cred = cus.fb_creds
    if user_fb_cred.present? && user_fb_cred.first.profile_pic_url.present?
      return { type:'image', value: user_fb_cred.first.profile_pic_url } 
    end

    contact_email = FullContactData.find_by_email(cus.email)
    if contact_email && contact_email.photo_url.present?
      return { type: 'image', value: contact_email.photo_url } 
    elsif cus.user_color.blank?
      cus.user_color = COLORS.sample.first
      cus.save
    end
    { type: 'color', value: cus.user_color }
  end

  private

  # Some users sign up with Rhombus numbers
  def phone_number_cannot_be_rhombus_number
    if User.exists?(rhombus_number: self.phone_number)
      errors.add(:phone_number, "can't be a Rhombus number. Please enter your phone number.")
    end
  end

  def set_merchant_org_phone
    if is_merchant?
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
    if is_merchant?
      EmailingService.send_welcome_email(self.email, owner.rhombus_number, "merchant")
    elsif self.user_level == 0
      ref = self.referrers.first
      message = Message.new
      unless ref.blank?
        referrer = User.find_by(id: ref.referrer_id)
        EmailingService.send_welcome_email_with_referral(referrer.email, self.email, referrer.org_name, referrer.rhombus_number, owner.rhombus_number)
        text = "Thanks for signing up! Please add a payment card to your Rhombus profile (if you haven't done so).
        You can chat with us anytime via sms or to make a payment, just text the amount & description/hashtag. Ex. +10 #donut"
        message.send_and_save_message(referrer.rn_type, referrer.rhombus_number, self.phone_number, text)
      else
        EmailingService.send_welcome_email(self.email, owner.rhombus_number, "customer")
        text = "Thanks for signing up! Please add a payment card to your Rhombus profile (if you haven't done so).
        You can chat with a local business anytime by texting their Rhombus number or to make a payment, just text the amount &
        description/hashtag. Ex. +10 #donut"
        message.send_and_save_message(owner.rn_type, owner.rhombus_number, self.phone_number, text)
      end
    end
  end

  # move to background job
  def update_phone_in_db
    if is_merchant?
      # is this phone_number or rhombus_number?
      if x = self.previous_changes['phone_number']
        ActiveRecord::Base.connection.execute("UPDATE messages SET messages.from = #{x[1]} WHERE messages.from = #{x[0]}")
        ActiveRecord::Base.connection.execute("UPDATE messages SET messages.to = #{x[1]} WHERE messages.to = #{x[0]}")
        # add transaction columns here too
      end
    end
  end

  def create_user_alert
    Alert.create_with(user_id: self.id).find_or_create_by(user_id: self.id)
  end

end
