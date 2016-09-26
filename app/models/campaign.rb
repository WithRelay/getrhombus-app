class Campaign < ActiveRecord::Base
  has_many :campaign_lists
  has_many :lists, through: :campaign_lists
  has_many :messages
  belongs_to :campaign
  has_one :message_frequency
end
