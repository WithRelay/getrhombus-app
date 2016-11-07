class Campaign < ActiveRecord::Base

  attr_accessor :list_ids
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
  enum frequency_type: { one_time: 0, recurring: 1 }
  enum status: { active: 1, paused: 2, inactive: 3 }
  # validation of campaign attributes
  validates_presence_of :name, :list_ids, :text
  validate :channel_text_validate, if: proc { |c| c.text.present? && !c.email? }
  validate :date_time_validate, if: proc { |c| c.recurring? || (c.one_time? && !c.deliver_now?) }
  # validation for repeat days if recurring is selected.
  validates_presence_of :repeat_days, if: lambda { recurring? }
  validates_presence_of :subject, if: lambda { email? }

  def from_user
    "#{first_name} #{last_name}"
  end

  def update_attributes(*args)
    campaign_lists.delete_all
    args[0][:list_ids].split(',').each { |list_id| campaign_lists.build(list_id: list_id).save }
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
      image_refs.build(image_id: avatar_id).save;
    end
  end

  private

  def date_time_validate
    # date_time.utc will convert date_time to utc and Time.now is current time and .utc will convert to utc
    errors.add(:date_time, 'date time should be greater than current date time') if date_time.utc < Time.now.utc
  end

  def channel_text_validate
    # the below key in the hash is the channel and the value represent the channel maximum text length
    channel_text_size = { 'sms' => 1550, 'facebook_messenger' => 300, 'mms' => 1550 }
    # get the text length by its key i.e. from params
    max_text_length = channel_text_size[channel]
    # add errors to text
    errors.add(:text, "text length should no more than #{max_text_length}") if max_text_length <= text.to_i
  end
end
