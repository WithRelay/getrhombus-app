# storing all campaign user list
class CampaignUserList < ActiveRecord::Base
  belongs_to :campaign
end
