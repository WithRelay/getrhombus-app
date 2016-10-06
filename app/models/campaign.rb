class Campaign < ActiveRecord::Base
  attr_accessor :list_id
  has_many :lists, through: :campaign_lists
  has_many :campaign_lists, dependent: :destroy
  has_many :messages, dependent: :destroy
  belongs_to :user
  has_many :image_refs, as: :imageable, dependent: :destroy
  has_many :images, through: :image_refs
  # enums for campaign's class attributes channel, status, frequency_type and delivery_type
  enum channel: { sms: 0, mms: 1, facebook_messenger: 2, email: 3 }
  enum status: { active: 1, paused: 2, inactive: 3 }
  enum frequency_type: { one_time: 0, recurring: 1 }
  enum delivery_type: { later: 0, now: 1 }
  # validation of campaign attributes
  validates_presence_of :channel, :repeat_days, :frequency_type, :text
end
