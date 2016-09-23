class Campaign < ActiveRecord::Base
  attr_accessor :list_id
  has_many :lists, through: :campaign_lists
  has_many :campaign_lists
  has_many :messages
  belongs_to :campaign
  enum channel: { sms_mms: '0', facebook_messenger: '1', email: '2' }
end
