# storing all campaign user list
class CampaignRecipient < ActiveRecord::Base
  belongs_to :campaign
  belongs_to :list
end
