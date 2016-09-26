class Campaign < ActiveRecord::Base
  attr_accessor :list_id
  has_many :lists, through: :campaign_lists
  has_many :campaign_lists
  has_many :messages
  enum channel: { sms: '0', mms: '1', facebook_messenger: '2', email: '3' }
  enum status: { active: 1, paused: 2, inactive: 3 }
  enum frequency_type: { one_time: '0', recurring: '1' }
  enum delivery_type: { now: '0', later: '1' }
  accepts_nested_attributes_for :messages
end
