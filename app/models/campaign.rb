class Campaign < ActiveRecord::Base

  attr_accessor :list_name
  has_many :campaign_user_lists
  has_many :lists, through: :campaign_lists
  has_many :campaign_lists, dependent: :destroy
  has_many :messages
  belongs_to :user
  has_many :image_refs, as: :imageable, dependent: :destroy
  has_many :images, through: :image_refs
  delegate :first_name, :last_name, to: :user
  # enums for campaign's class attributes channel, status, frequency_type and delivery_type
  enum channel: { sms: 0, mms: 1, facebook_messenger: 2, email: 3 }
  enum campaign_type: { promo_campaign: 0, reminder_campaign: 1 }
  enum frequency_type: { one_time: 0, recurring: 1 }
  enum status: { active: 1, paused: 2, inactive: 3, test: 4 }
  # validation of campaign attributes
  validates_presence_of :name, :list_name, unless: lambda { reminder_campaign? }
  validates_presence_of :text

  validate :channel_text_validate, if: proc { |c| c.text.present? && !c.email? }
  validate :date_time_validate, if: proc { |c| c.recurring? || (c.one_time? && !c.deliver_now?) }
  # validation for repeat days if recurring is selected.
  validates_presence_of :repeat_days, if: lambda { recurring? }
  validates_presence_of :subject, if: lambda { email? }
  validate :total_image_size
  validates :name, uniqueness: { case_sensitive: false, scope: :user_id }, unless: lambda { reminder_campaign? }
  # scopes
  scope :check_campaign_uniqueness, -> (campaign_name) { where('lower(name) = ?', campaign_name.downcase) }


  def from_user
    "#{first_name} #{last_name}"
  end

  def update_attributes(*args)
    campaign_lists.delete_all
    args[0][:list_name].split(',').each { |list_id| campaign_lists.build(list_id: list_id).save }
    # creates records for attachment images associating with campaign
    create_avatar(args[1]) if (!sms? && args[1][:avatar].present?)
    # creates records for inline images associating with campaign
    create_image_refs(args[1]) if args[1][:image_id].present?
    # super calls a parent class update_attributes function and updates campaign attributes
    super(args[0])
  end

  def create_avatar(image_params)
    image_params[:avatar].each do |image|
      images.build(avatar: image, uploaded_as: 1)
    end
  end

  def create_image_refs(campaign_image)
    args[1][:image_id].each do |avatar_id|
      image_refs.build(image_id: avatar_id).save
    end
  end

  def change_campaign_job
    destroy_campaign_jobs
    enqueue_jobs if active? || one_time? && deliver_now?
  end

  def destroy_campaign_jobs
    Resque.remove_delayed_selection { |args| args[0] == id }
  end

  def enqueue_jobs
    # rescue enqueue_at_with_queue accepts four parametera 1 name of queue, 2 date_time(provided as utc)
    # 3 class name 4 the parameter send for class method perform
    Resque.enqueue_at_with_queue('one_time_campaign', date_time.utc, OneTimeCampaignJob, id) if is_campaign_date_selected? || is_today_campaign?
    SendNowCampaignJob.perform_now({ campaign_id: self.id }) if deliver_now?
  end

  private

  def is_today_campaign?
    date_time.strftime("%Y-%m-%d") == Time.current.strftime("%Y-%m-%d") if date_time.present?
  end

  def date_time_validate
    # date_time.utc will convert date_time to utc and Time.now is current time and .utc will convert to utc
    # no need to convert to datetime object because rails tries to save date time by storing to date time format
    # so the self object date_time attribute returns the date time which is formatted in rails date time
    errors.add(:date_time, 'should be 30 minutes greater than current date time') if is_time_greater_than_now?
  end

  def is_time_greater_than_now?
    (date_time - 30.minutes) < Time.current if date_time.present?
  end

  def is_campaign_date_selected?
    (one_time? && !deliver_now?)
  end

  def total_image_size
    total_size = self.images.inject(0){ |sum, image| sum += image.avatar_file_size }
    channel_max_image_upload = { 'email' => 25.megabytes, 'mms' => 5.megabytes }
    get_total_allowed_size = channel_max_image_upload[self.channel]
    unless get_total_allowed_size.nil?
      errors.add(:images, "size not be greater than #{get_total_allowed_size/1_048_576} MB") if total_size > get_total_allowed_size
    end
  end

  def reminder_campaign?
    self.is_a?(Reminder)
  end

  def channel_text_validate
    # the below key in the hash is the channel and the value represent the channel maximum text length
    channel_text_size = { 'sms' => 1550, 'facebook_messenger' => 300, 'mms' => 1550 }
    # get the text length by its key i.e. from params
    max_text_length = channel_text_size[channel]
    # add errors to text
    errors.add(:text, "length should no more than #{max_text_length}") if max_text_length <= text.length
  end
end
