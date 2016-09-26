class CampaignList < ActiveRecord::Base
  belongs_to :campaign
  belongs_to :list
end
