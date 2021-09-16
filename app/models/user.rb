# frozen_string_literal: true

class User < ActiveRecord::Base
  extend UserProfile
  include CSVHandler
  include AddTokenToUser
  include Transactionable

  attr_accessor :phone, :msg_id, :captured_amt, :referrer
  attr_accessor :channel, :referrer_uid, :tos_acceptance, :customer_source
  attr_accessor :card_token, :page_specific_id
  # attr_accessor :area_code, :rn_country, :rn_type # These accessors aren't needed anymore

  NUMBER_PRICE = 1
  SIGNUP_EMAIL_DELAY = 120
  INCOMPLETE_SIGNUP_EMAIL_DELAY = 720

  delegate :url_helpers, to: 'Rails.application.routes'

  # These validations cause issues with existing merchants who do not have the fields set. Need to revisit.
  # Client side validation will take care of this for now.
  # validates :tos_acceptance, acceptance: true, if: lambda { self.is_merchant? && self.reset_password_token.blank? }, on: :update
  # validates :org_type, presence: true, if: lambda { self.is_merchant? && self.reset_password_token.blank? }, on: :update
  # Edit pages use the right number field for each user type
  # validates :org_phone, numericality: { only_integer: true }, length: { minimum: 10 }, on: :update, if: lambda { self.is_merchant? && self.reset_password_token.blank? }
  # validates :phone_number, presence: true, numericality: { only_integer: true }, length: { minimum: 10 }, on: :update, if: lambda { self.is_customer? && self.reset_password_token.blank? }
  # validates_presence_of :org_name, if: lambda { self.is_merchant? && self.org_type.try(:downcase) != 'individual' && self.reset_password_token.blank? }, on: :update

  validates_presence_of :user_level, message: 'Please select an account type', on: :create
  validate :phone_number_cannot_be_rhombus_number

  # Sign up form uses phone_number field for both user types
  validates :phone_number, presence: true, numericality: { only_integer: true }, length: { minimum: 10 }, on: :create

  # Allow nil added to db migration because merchants don't have phone number. They have org_phone.
  # And since mysql indexes this field, it indexes nil and only allows one row with nil.
  # You run into issues with any additional merchants.
  validates_uniqueness_of :phone_number, allow_nil: true, if: -> { is_customer? }

  # include default devise modules. Others available are: :token_authenticatable, :lockable, :timeoutable and :confirmable,
  devise :database_authenticatable, :registerable, :recoverable, :rememberable, :trackable, :validatable, :omniauthable, omniauth_providers: %i[facebook twitter stripe_connect]

  has_many :customer_transactions, class_name: 'Transaction', foreign_key: 'user_id'
  has_many :merchant_transactions, class_name: 'Transaction', foreign_key: 'team_id'

  has_one :referrer, class_name: 'Referrer', foreign_key: 'referee_id'
  has_many :referees, class_name: 'Referrer', primary_key: :relay_uid, foreign_key: :referrer_uid

  has_many :merchant_contacts, class_name: 'MerchantContact', foreign_key: 'merchant_id'
  has_many :customer_merchants, class_name: 'MerchantCustomer', foreign_key: 'customer_id'
  has_many :merchant_customers, class_name: 'MerchantCustomer', foreign_key: 'merchant_id'

  belongs_to :sms_fee
  has_one :hosted_sms
  has_one :api_cred
  has_many :rules, -> { order(created_at: :asc) }
  has_many :reminders, -> { where campaign_type: Campaign.campaign_types[:reminder_campaign] }

  # this block is for customizing build method for user.campaign which allow also to save list
  has_many :campaigns, -> { where campaign_type: Campaign.campaign_types[:promo_campaign] } do
    # overiding association build function like user.campaigns.build will hit here
    def build(*args)
      # calls parent build action and send arguments first from the splat operator
      campaign = super(args[0])
      unless args.blank?
        # build campaign lists of campaign
        list_id = args[0][:list_id]
        campaign.campaign_lists.build(list_id: list_id) if list_id.present?
        # build avatar of campaigns
        if args[1].present?
          if (!campaign.sms? && args[1][:avatar].present?) && campaign.valid?
            campaign.images.build(avatar: args[1][:avatar], uploaded_as: 1)
          end
          # build image refs for inline images of campaigns
          if args[1][:image_id].present?
            args[1][:image_id].each do |avatar_id|
              campaign.image_refs.build(image_id: avatar_id).save
            end
          end
        end
      end
      campaign
    end
  end

  has_many :hashtags
  has_many :documents
  has_one :away_message

  has_many :messages
  has_many :merchant_conversations, class_name: 'Conversation', foreign_key: 'merchant_id'
  has_many :customer_conversations, -> { where uid_type: 'user' }, class_name: 'Conversation', foreign_key: 'uid'

  has_many :merchant_plans, class_name: 'Plan', foreign_key: 'merchant_id'
  has_many :merchant_only_plans, -> { where customer_id: nil }, class_name: 'Plan', foreign_key: 'merchant_id'
  has_many :customer_plans, class_name: 'Plan', foreign_key: 'customer_id'

  has_many :coupons
  has_many :saas_invoices, -> { where team_id: User.get_platform_acct_obj.id }, class_name: :Invoice, foreign_key: :customer_id
  # LEAVE THIS FOR LATER
  # has_many :next_plans

  has_one :twitter_cred
  has_many :fb_creds

  has_one :alert, dependent: :destroy
  has_many :fb_pages, dependent: :destroy

  has_many :saved_replies
  has_many :message_resolutions

  # A user can have belong to more than one list and also own multiple lists (Admins)
  has_many :lists
  has_many :user_lists, as: :customer_contact
  accepts_nested_attributes_for :user_lists
  has_many :segments, -> { where.not(segment: nil) }, class_name: 'List'

  has_many :bank_accounts
  accepts_nested_attributes_for :bank_accounts
  validates_associated :bank_accounts

  has_one :standalone_stripe_cred
  has_many :stripe_creds, -> { extending PersistedExtension }
  accepts_nested_attributes_for :stripe_creds

  has_one :address, as: :addressable
  accepts_nested_attributes_for :address
  validates_associated :address

  has_many :people
  accepts_nested_attributes_for :people, allow_destroy: true # reject_if: ->(attrs) { attrs['city'].blank? || attrs['street'].blank? }

  has_one :default_number, -> { where(default: 1) }, class_name: 'Number'
  has_many :numbers

  before_validation :the_titleizer
  before_create :set_merchant_org_phone # only create because the actual org_phone field is used in edit view

  after_commit :do_signup_stuff, on: :create

  enum status: { inactive: 0, active: 1, fraudulent: 2, api_only: 3 }

  def is_api_user?
    api_cred.present?
  end

  def is_customer?
    user_level == 0
  end

  def is_platform?
    email == User.platform_email
  end

  def is_merchant?
    user_level == 1 || is_platform?
  end

  def get_page_access_token
    fb_pages.subscribed.last
  end

  # def self.platform_email; '<redacted_email>' end
  def self.platform_email
    Rails.application.secrets.team_email
  end

  def self.get_platform_acct_obj
    User.find_by(email: User.platform_email)
  end

  def deduct_from_account_balance(amt)
    decrement!(:account_balance, amt.to_f)
  end

  def imkgp?
    email.end_with?('@rmgsite.com') || email.end_with?('@imkgp.com') || is_platform?
  end

  # def friendly_relay_number; self.rn_friendly_name.present? ? self.rn_friendly_name : self.rhombus_number end
  # A default number must always exists for active accounts
  def rhombus_number
    default_number.try(:number)
  end

  def friendly_relay_number
    dn = default_number
    return '' unless dn

    dn.friendly_name.present? ? dn.friendly_name : dn.number
  end

  def managed_account_is_verified?
    stripe_creds.first.try(:legal_entity_verification).try(:[], 'status') == 'verified'
  end

  def full_name
    return card_name.to_s if is_customer? && card_name.present?

    fn = people[0].try(:full_name)
    fn.present? ? fn : email
  end

  def first_name
    first_name = full_name.split.first
    first_name.present? ? first_name : nil
  end

  def user_title
    user_first_name = first_name
    user_first_name.present? ? "#{user_first_name} from #{org_name}" : org_name
  end

  def get_stripe_cred
    # platform acct is identified as standalone account but it really isnt
    # merchants could have a standalone account (prior to v1.5) and a managed account
    # managed account takes priority
    return { type: 'standalone', cred: {} } if is_platform?

    cred = stripe_creds # check for managed account first, we support just one account for now
    return { type: 'managed', cred: cred.first } if cred.present?

    cred = standalone_stripe_cred # check for standalone ... this is legacy
    return { type: 'standalone', cred: cred } if cred.present?

    { type: nil, cred: nil } # has no payment account
  end

  def can_accept_payments?(skip_check_managed_acct_status = false)
    return true if is_platform?

    cred = get_stripe_cred
    return true if cred[:type] == 'managed' && skip_check_managed_acct_status
    return true if cred[:type] == 'managed' && cred[:cred].charges_enabled?
    return true if cred[:type] == 'standalone'

    false
  end

  def can_accept_subscriptions?
    return true if is_platform?

    cred = get_stripe_cred
    return true if cred[:type] == 'managed' && cred[:cred].charges_enabled?

    false
  end

  def buy_number(params, default = true, with_uid = true)
    number = TextingService.buy_number({ query: params['area_code'] || '', country: params['rn_country'], type: params['rn_type'] })
    EmailingService.hosted_sms_progress_notice(self, number.try(:second)) if hosted_sms.present?
    return false unless number

    if with_uid
      uid = generate_uid
      url = "#{url_helpers.new_user_registration_url}?referrer_uid=#{uid}"
      # self.update(relay_uid: uid, rhombus_number: number[0], rn_friendly_name: number[1], short_url: url, rn_type: params["rn_type"], rn_country: params["rn_country"])
      update(relay_uid: uid, short_url: url)
    end

    numbers.create(number: number[0], friendly_name: number[1], number_type: params['rn_type'], country: params['rn_country'], default: default)

    # deduct_from_account_balance(NUMBER_PRICE)

    # welcome_text = "Howdy! Wondering how to get started? Add or import your customers and contacts to start messaging them immediately. If you have any questions, message us here and a member of our team will be happy to help."
    # Conversation.find_or_create_conversation_for_message_and_send_publish(User.get_platform_acct_obj, self, 'user', self.id, welcome_text)
  end

  def has_valid_card?
    return { valid: false, text: 'No valid card on file', type: 'no_source' } if card_id.blank?
    if exp_year.to_i > Time.current.year || (exp_year.to_i == Time.current.year && exp_month.to_i >= Time.current.month)
      return { valid: true }
    end

    { valid: false, text: 'Default card has expired', type: 'expired_source' }
  end

  def get_saas_subscription
    platform_merchant = MerchantCustomer.find_by(customer_id: id, merchant_id: User.get_platform_acct_obj.id)
    # this will return false positives for merchants who have changed subscriptions
    platform_merchant.try(:subscriptions).try(:includes, :plan).try(:last)
  end

  def get_customer_page_specific_id(page_access_token)
    return unless page_access_token

    (page = FbPage.find_by(page_access_token: page_access_token)) || return
    fb_creds.where(fb_page_id: page.id).last.try(:page_specific_id)
  end

  def is_active_merchant?
    count = Transaction.where(team_id: id).count + MerchantCustomer.where(merchant_id: id).count
    + Message.where('user_id = ? or user_id_to = ?', id, id).count
    + FbMessage.where('user_id = ? or user_id_to = ?', id, id).count
    count > 0
  end

  def create_fibernetics_subscriber(validate_carrier = true)
    # re = TextingService.create_fibernetics_subscriber(self.rhombus_number)
    # self.update_columns(fn_subscriber_id: re, rn_friendly_name: nil, rn_type: nil, rn_country: nil) if re

    user_numbers = numbers
    user_numbers.each do |un|
      re = TextingService.create_fibernetics_subscriber(un.number, validate_carrier)
      un.update_columns(fibernetics_subscriber_id: re) if re
    end
  end

  def z
    Stripe::Account.update(
      '<redacted_stripe_account_id>',
      {
        requested_capabilities: %w[card_payments transfers]
      },
      {
        stripe_version: '<redacted_phone_number>',
        stripe_account: '<redacted_stripe_account_id>'
      }
    )
  rescue Exception => e
    puts e.inspect
  end

  def q
    Stripe::Account.update(
      '<redacted_stripe_account_id>',
      {
        settings: {
          payments: { statement_descriptor: 'xyzx1' },
          card_payments: { statement_descriptor_prefix: 'xyz' }
        }
      },
      {
        stripe_version: '<redacted_phone_number>'
      }
    )
  rescue Exception => e
    puts e.inspect
  end

  def y
    last_id = nil
    more_data = true

    while more_data
      params = { limit: 100 }
      params[:starting_after] = last_id if last_id

      data = Stripe::Account.list(params)['data']
      last_id = data[data.size - 1].try(:[], 'id')
      more_data = false unless last_id

      next unless last_id

      data.each do |o|
        begin
          puts "Update #{o['id']}"
          Stripe::Account.update(
            o['id'],
            {
              requested_capabilities: %w[card_payments transfers],
              stripe_account: o['id']
            },
            {
              stripe_version: '<redacted_phone_number>'
            }
          )
        rescue Exception => e
          puts e.inspect
          puts "\n\n\n\n\n\n\n"
        end
      end
    end
  end

  private

  # Some users sign up with Relay numbers
  def phone_number_cannot_be_rhombus_number
    # if self.phone_number.present? && User.exists?(rhombus_number: self.phone_number)
    if phone_number.present? && Number.unscoped.exists?(number: phone_number)
      errors.add(:phone_number, "can't be a Relay number. Please enter your phone number.")
    end
  end

  def set_merchant_org_phone
    self.attributes = { org_phone: phone_number, phone_number: nil } if is_merchant?
  end

  def the_titleizer
    %i[url custom_welcome org_name].each { |a| self[a].try(:strip!) }
    return if card_name.blank?

    self.card_name = card_name.strip.titleize
  end

  def do_signup_stuff
    if !is_platform? && customer_source.try(:[], :method).try(:exclude?, 'added')
      MerchantCustomer.add_or_update_merchant_customer(User.get_platform_acct_obj, self)
    end

    if is_merchant?
      List.new.create_default_segments(self)
      GetIntelligenceDataJob.perform_later(org_phone, 'OpenCNAM')
      IncompleteSignupJob.set(wait: INCOMPLETE_SIGNUP_EMAIL_DELAY.seconds).perform_later(self)
      AwayMessage.find_or_create_by(user_id: id, response: "We're away at the moment and will get back to you when we return :).")
    end

    GetIntelligenceDataJob.perform_later(email, 'FullContact')
    GetIntelligenceDataJob.perform_later(phone_number, 'OpenCNAM') if is_customer?
    unless customer_source.try(:[], :method).try(:include?, 'skip_email')
      WelcomeEmailJob.set(wait: SIGNUP_EMAIL_DELAY.seconds).perform_later(self, customer_source)
    end
  rescue StandardError => e
    ExceptionNotifier.notify_exception(e, data: { message: 'From do_signup_stuff', self: self, env: Rails.env })
  end

  # def validates_person_full_message
  #   leave out. but this code needs to be changed
  #   errors.add(:full_name, 'is required') if self.people[0].try(:full_name).present?
  # end
end
