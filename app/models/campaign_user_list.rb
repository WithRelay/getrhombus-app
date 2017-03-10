# storing all campaign user list
class CampaignUserList < ActiveRecord::Base
  belongs_to :campaign
  belongs_to :reminder
end
