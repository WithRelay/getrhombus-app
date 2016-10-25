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
  # validation for repeat days if recurring is selected.
  validates_presence_of :repeat_days, if: lambda { recurring? }

  def from_user
    "#{first_name} #{last_name}"
  end

  def channel_text_validate
    # the below key in the hash is the channel and the value represent the channel maximum text length
    channel_text_size = { 'sms' => 1500, 'facebook_messenger' => 320 }
    # get the text length by its key i.e. from params
    max_text_length = channel_text_size[channel]
    # add errors to text
    errors.add(:text, "text length should no more than #{max_text_length}") if max_text_length <= text.to_i
  end
end
