class Campaign < ActiveRecord::Base

  attr_accessor :list_id
  
  belongs_to :user
  has_many :messages
  has_many :user_lists, through: :lists
  has_many :lists, through: :campaign_lists
  has_many :campaign_lists, dependent: :destroy
  has_many :campaign_recipients, dependent: :destroy
  has_many :image_refs, as: :imageable, dependent: :destroy
  has_many :images, through: :image_refs

  # enums for campaign's class attributes channel, status, frequency_type and delivery_type
  enum frequency_type: { one_time: 0, recurring: 1 }
  enum status: { active: 1, paused: 2, inactive: 3, test: 4 }
  enum campaign_type: { promo_campaign: 0, reminder_campaign: 1 }
  enum channel: { sms: 0, mms: 1, facebook_messenger: 2, email: 3 }
  
  # validation of campaign attributes
  validates_presence_of :text
  validates_presence_of :name, :list_id, unless: lambda { reminder_campaign? }
  validate :channel_text_validate, if: proc { |c| c.text.present? && !c.email? }

  # uncomment this for production
  #validate :validate_date_time, if: proc { |c| c.recurring? || (c.one_time? && !c.deliver_now?) }
  
  validate :total_image_size
  validates_presence_of :subject, if: lambda { email? } 
  validates_presence_of :repeat_days, if: lambda { recurring? }  
  validates :name, uniqueness: { case_sensitive: false, scope: :user_id }, unless: lambda { reminder_campaign? }
  
  # scopes 
  scope :check_campaign_uniqueness, -> (campaign_name) { where('lower(name) = ?', campaign_name.downcase) }  
  scope :is_active_or_paused, -> { where(status: [Campaign.statuses[:active], Campaign.statuses[:paused]]) }  

  before_create :set_campaign_status
  before_save :update_next_send_at, if: lambda { (recurring? || (one_time? && !deliver_now?)) && date_time_changed? }

  def update_attributes(*args)
    campaign_lists.delete_all
    args[0][:list_id].split(',').each { |lid| campaign_lists.build(list_id: lid).save }
    # creates records for attachment images associating with campaign
    images.build(avatar: args[1][:avatar], uploaded_as: 1) if (!sms? && args[1][:avatar].present?)
    # creates records for inline images associating with campaign
    create_image_refs(args[1]) if args[1][:image_id].present?
    # super calls a parent class update_attributes function and updates campaign attributes
    super(args[0])
  end

  def create_image_refs(campaign_image)
    args[1][:image_id].each do |avatar_id|
      image_refs.build(image_id: avatar_id).save
    end
  end

  def reminder_campaign?
    self.is_a?(Reminder)
  end

  def destroy_campaign_jobs
    Resque::Job.destroy(send_now_queue, SendNowCampaignJob, self.id)
    Resque::Job.destroy(pending_queue, PendingCampaignsHandlerJob, self.id)
    Resque.remove_delayed_selection(PendingCampaignsHandlerJob) { |args| args[0] == self.id }
  end

  def change_campaign_job
    destroy_campaign_jobs
    enqueue_jobs
  end

  def enqueue_jobs
    if self.active? || self.test?
      rescue_job_queue if is_todays_campaign?
      send_now_campaign if deliver_now?
    end
  end

  def change_job_status
    destroy_campaign_jobs
    # after reactivating campaign, put back in queue if campaign is today and upcoming. no need to consider deliver now
    rescue_job_queue if self.active? && is_todays_campaign?
  end

  def rescue_job_queue
    if reminder_campaign?
      Resque.enqueue_at_with_queue(pending_queue, date_time.utc, PendingCampaignsHandlerJob, id)
    else
      Resque.enqueue_at_with_queue(pending_queue, date_time.utc, PendingCampaignsHandlerJob, id)
    end
  end

  def send_now_campaign
    SendNowCampaignJob.set(queue: send_now_queue).perform_later(self.id) if !reminder_campaign?
    SendNowCampaignJob.set(queue: send_now_queue).perform_later(self.id) if reminder_campaign?
  end

  def pending_queue
    if reminder_campaign?
      queue = self.recurring? ? '_recurring_reminders' : '_one_time_reminders'
    else
      queue = self.recurring? ? '_recurring_campaigns' : '_one_time_campaigns'
    end
    Rails.env + queue
  end

  def send_now_queue
    Rails.env + (reminder_campaign? ? "_send_now_reminders" : "_send_now_campaigns")
  end

  private

  def update_next_send_at
    self.next_send_at = self.date_time
  end

  def is_todays_campaign?
    if date_time.present?
      now = Time.current.to_i
      tomorrow = Time.current.tomorrow.beginning_of_day.to_i
      return date_time.to_i > now && date_time.to_i < tomorrow
    end
  end

  def validate_date_time
    if date_time.present? && (date_time - 30.minutes).to_i < Time.current.to_i
      errors.add(:date_time, 'should be at least after the next half hour')
    end
  end

  def total_image_size
    total_size = self.images.inject(0) { |sum, image| sum += image.avatar_file_size }
    channel_max_image_upload = { 'email' => 20.megabytes, 'mms' => (4.5).megabytes }
    get_total_allowed_size = channel_max_image_upload[self.channel]
    unless get_total_allowed_size.nil?
      errors.add(:images, "size not be greater than #{get_total_allowed_size/1_048_576} MB") if total_size > get_total_allowed_size
    end
  end

  # sets campaign status as inactive because merchant do not have facebook messenger associated
  def set_campaign_status
    if !self.user.get_page_access_token.present? && self.facebook_messenger? && !self.test?
      self.status = Campaign.statuses[:inactive]
    elsif !self.test?
      self.status = Campaign.statuses[:active]
    end
  end

  def channel_text_validate
    channel_text_size = { 'sms' => 1550, 'facebook_messenger' => 300, 'mms' => 1550 }
    max_text_length = channel_text_size[channel]
    errors.add(:text, "length should no more than #{max_text_length} characters") if max_text_length < text.length
  end
end
