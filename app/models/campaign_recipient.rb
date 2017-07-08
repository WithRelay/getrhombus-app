# storing all campaign user list
class CampaignRecipient < ActiveRecord::Base
  belongs_to :campaign
  belongs_to :list

  enum channel: { sms: 0, mms: 1, facebook_messenger: 2, email: 3 }
end
