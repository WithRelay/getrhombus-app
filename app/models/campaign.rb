class Campaign < ActiveRecord::Base
  attr_accessor :list_id
  has_many :lists, through: :campaign_lists
  has_many :campaign_lists
  has_many :messages
  enum channel: { sms: '0', mms: '1', facebook_messenger: '2', email: '3' }
end
