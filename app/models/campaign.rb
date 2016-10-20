class Campaign < ActiveRecord::Base

  attr_accessor :list_ids
  has_many :lists, through: :campaign_lists
  has_many :campaign_lists, dependent: :destroy
  has_many :messages
  belongs_to :user
  has_many :image_refs, as: :imageable, dependent: :destroy
  has_many :images, through: :image_refs
  delegate :first_name, :last_name, to: :user
  # enums for campaign's class attributes channel, status, frequency_type and delivery_type
  enum channel: { SMS: 0, MMS: 1, :"Facebook Messenger" => 2, Email: 3 }
  enum frequency_type: { one_time: 0, recurring: 1 }
  enum status: { active: 1, paused: 2, inactive: 3 }
  # validation of campaign attributes
  validates_presence_of :text, :name, :list_ids
  # validation for repeat days if recurring is selected.
  validates_presence_of :repeat_days, if: lambda { recurring? }

  def from_user
    "#{first_name} #{last_name}"
  end
end
