class User < ActiveRecord::Base

  extend UserProfile
  include DashboardMerchantQueries
  include CSVHandler
  include AddTokenToUser
  include Transactionable

  attr_accessor :phone, :captured_amt, :msg_id, :tag_id
  attr_accessor :referrer_uid, :tos_acceptance, :area_code

  # validation rules for user attributes
  validates :tos_acceptance, acceptance: true, if: lambda { self.is_merchant? && self.reset_password_token.blank? }, on: :update
  validates :org_type, presence: true, if: lambda { self.is_merchant? && self.reset_password_token.blank? }, on: :update

  validates_presence_of :org_name, if: lambda { self.is_merchant? && self.org_type.try(:downcase) != 'individual' && self.reset_password_token.blank? }, on: :update
  validates_presence_of :user_level, message: "Please select an account type", on: :create

  validate :phone_number_cannot_be_rhombus_number

  # Edit pages use the right number field for each user type
  validates :org_phone, numericality: { only_integer: true }, length: { minimum: 10 }, on: :update, if: lambda { self.is_merchant? && self.reset_password_token.blank? }
  validates :phone_number, presence: true, numericality: { only_integer: true }, length: { minimum: 10 }, on: :update, if: lambda { self.is_customer? && self.reset_password_token.blank? }

  # Sign up form uses phone_number field for both user types
  validates :phone_number, presence: true, numericality: { only_integer: true }, length: { minimum: 10 }, on: :create
  validate :validates_person_full_message

  # Allow nil added to db migration because merchants don't have phone number. They have org_phone.
  # And since mysql indexes this field, it indexes nil and only allows one row with nil.
  # You run into issues with any additional merchants.
  validates_uniqueness_of :phone_number, allow_nil: true, if: lambda { self.is_customer? }

  # include default devise modules. Others available are: :token_authenticatable, :lockable, :timeoutable and :confirmable,
  devise :database_authenticatable, :registerable, :recoverable, :rememberable, :trackable, :validatable, :omniauthable, :omniauth_providers => [:facebook, :twitter, :stripe_connect]

  has_many :customer_transactions, class_name: 'Transaction', foreign_key: 'user_id'
  has_many :merchant_transactions, class_name: 'Transaction', foreign_key: 'team_id'

  has_many :referrers, class_name: 'Referrer', foreign_key: 'referee_id'
  has_many :referees, class_name: 'Referrer', primary_key: :relay_uid, foreign_key: :referrer_uid

  has_many :customer_merchants, class_name: 'MerchantCustomer', foreign_key: 'customer_id'
  has_many :merchant_customers, class_name: 'MerchantCustomer', foreign_key: 'merchant_id'
  has_many :customers, class_name: 'User', through: :merchant_customers

  has_many :merchant_contacts, class_name: 'MerchantContact', foreign_key: 'merchant_id'

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

  has_one :away_message
  has_many :hashtags

  has_many :messages
  has_many :merchant_conversations, class_name: 'Conversation', foreign_key: 'merchant_id'
  has_many :customer_conversations, -> { where uid_type: 'user' }, class_name: 'Conversation', foreign_key: 'uid'

  has_many :merchant_plans, class_name: 'Plan', foreign_key: 'merchant_id'
  has_many :customer_plans, class_name: 'Plan', foreign_key: 'customer_id'
  has_many :coupons
  # LEAVE THIS FOR LATER
  #has_many :next_plans

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
  accepts_nested_attributes_for :user_lists

  has_many :bank_accounts
  accepts_nested_attributes_for :bank_accounts
  validates_associated :bank_accounts

  has_one :standalone_stripe_cred
  has_many :stripe_creds
  accepts_nested_attributes_for :stripe_creds

  has_one :address, as: :addressable
  accepts_nested_attributes_for :address
  validates_associated :address

  has_many :people
  accepts_nested_attributes_for :people, allow_destroy: true  # reject_if: ->(attrs) { attrs['city'].blank? || attrs['street'].blank? }

  before_validation :the_titleizer
  before_create :set_merchant_org_phone          # only create because the actual org_phone field is used in edit view

  after_commit :do_signup_stuff, on: :create

  enum status: { inactive: 0, active: 1 }

  def is_merchant?
    user_level == 1
  end

  def is_customer?
    user_level == 0
  end

  def full_name
    return "#{self.card_name}" if self.is_customer?
    "#{self.people.representative[0].try(:first_name)} #{self.people.representative[0].try(:last_name)}"
  end

  def is_platform?
    #email == User.platform_email
    self.email == '<redacted_email>' || self.email == '<redacted_email>'
  end

  def self.user_title(user)
    user_first_name = user.full_name.split.first
    user_first_name.present? ? "#{user_first_name} from #{user.org_name}" : user.org_name
  end

  def get_stripe_cred
    # platform acct is a standalone account
     # merchants could have a standalone account (prior to v1.5) and a managed account
     # managed account takes priority

     # remove this eventually
     return { type: 'standalone', cred: User.find_by(id: 23) }
     ##
     return { type: 'standalone', cred: self.standalone_stripe_cred } if is_platform?

     cred = self.stripe_creds   # check for managed account first
     return { type: 'managed', cred: cred.first } if cred.present?

     cred = self.standalone_stripe_cred  # check for standalone ... this is legacy
     return { type: 'standalone', cred: cred } if cred.present?

     { type: nil, cred: nil }  # has no payment account
  end

  def self.platform_email
    Rails.application.secrets.dashboard_email
  end

  def self.get_platform_acct_obj
    # you can change this temporarily to <redacted_email> or <redacted_email>
    # User.find_by(email: User.platform_email)
    User.find_by(email: "<redacted_email>") || User.find_by(email: "<redacted_email>")
  end

  def buy_number(params)
    number = TextingService.buy_number({ query: params["area_code"] || "", country: params["rn_country"], type: params["rn_type"] })
    return false unless number
    self.rhombus_number = number[0]
    self.rn_friendly_name = number[1]
    # get_uid_and_referrer_link
    self.update_account_balance(NUMBER_PRICE)
  end

  def has_valid_card?
    return [false, 'No valid card on file'] if self.card_token.blank? || self.exp_year.blank? || self.exp_month.blank?
    return [true] if self.exp_year.to_i >= Time.current.year && self.exp_month.to_i >= Time.current.month
    return [false, 'Card has expired.']
  end

  def get_saas_subscription
    platform_merchant = MerchantCustomer.find_by(customer_id: self.id, merchant_id: User.get_platform_acct_obj.id)
    platform_merchant ? platform_merchant.subscriptions.active.last : nil
  end

  def get_page_access_token
    page = self.fb_pages.subscribed[0]
    page.try(:page_access_token)
  end

  def get_customer_page_specific_id(page_access_token)
    page = FbPage.find_by(page_access_token: page_access_token)
    fb_cred = self.fb_creds.where(fb_page_id: page.id).last
    fb_cred.try(:page_specific_id)
  end

  def user_segments
    self.lists.where.not(segment: nil)
  end

  def update_account_balance(amt)
    self.update(account_balance: (self.account_balance - amt.to_f).round(6))
  end

  private

  # Some users sign up with Rhombus numbers
  def phone_number_cannot_be_rhombus_number
    if self.phone_number.present? && User.exists?(rhombus_number: self.phone_number)
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

  def do_signup_stuff
    user_id = self.id
    if self.is_merchant?
      Alert.find_or_create_by(user_id: user_id)
      response = "We're away at the moment and will get back to you when we return :)."
      AwayMessage.find_or_create_by(user_id: user_id, response: response)
      GetIntelligenceDataJob.perform_later(self.org_phone, 'OpenCNAM')
      segment_dynamic_customers = "MerchantCustomer.where('created_at >= ? AND merchant_id = ?',
                                  Time.now - 7.days, #{user_id})"

      segment_dynamic_contacts = "MerchantContact.where('created_at >= ? AND merchant_id = ?',
                                  Time.now - 7.days, #{user_id})"

      self.lists.create(name: 'New customers', segment: segment_dynamic_customers, origin: 1, list_type: 0)
      self.lists.create(name: 'New customers', segment: segment_dynamic_contacts, origin: 1, list_type: 1)

      new_segment_customers = %Q{Transaction.where("created_at >= ? AND user_id IN(?) AND team_id = ?",
                                Time.current - 30.days, MerchantCustomer.where(merchant_id: #{user_id})
                                .pluck(:customer_id) | FbMessage.where("created_at >=? AND
                                user_id_to = ? AND user_id IN(?)", Time.current - 30.days, #{user_id},
                                MerchantCustomer.where(merchant_id: #{user_id}).pluck(:customer_id)),
                                #{user_id})}

      new_segment_contacts = %Q{Transaction.where("created_at >= ? AND user_id IN(?) AND team_id = ?",
                                Time.current - 30.days, MerchantContact.where(merchant_id: #{user_id})
                                .pluck(:uid) | FbMessage.where("created_at >=? AND
                                user_id_to = ? AND user_id IN(?)", Time.current - 30.days, #{user_id},
                                MerchantContact.where(merchant_id: #{user_id}).pluck(:uid)),#{user_id})}

      self.lists.create(name: 'Active Customers', segment: new_segment_customers, origin: 1, list_type: 0)
      self.lists.create(name: 'Active Customers', segment: new_segment_contacts, origin: 1, list_type: 1)
      self.lists.create(name: 'Inactive Customers', segment: new_segment_customers, origin: 1, list_type: 0)
      self.lists.create(name: 'Inactive Customers', segment: new_segment_contacts, origin: 1, list_type: 1)
    end
    MerchantCustomer.add_or_update_merchant_customer(User.get_platform_acct_obj.id, user_id)
    WelcomeEmailJob.set(wait: SIGNUP_EMAIL_DELAY.minutes).perform_later(self)
    GetIntelligenceDataJob.perform_later(self.email, 'FullContact')
    GetIntelligenceDataJob.perform_later(self.phone_number, 'OpenCNAM') if self.is_customer?
  end

  def validates_person_full_message
    errors.add(:full_name, 'is required') if self.people[0].try(:full_name).present?
  end

  # This is the link merchants can share...also dashboard link
  def get_uid_and_referrer_link
    self.relay_uid = generate_uid
    self.short_url = "dasd" #UrlShorternerService.shorten_link("https://www.withrelay.com/signup?referrer_uid=#{self.relay_uid}")
  end
end
