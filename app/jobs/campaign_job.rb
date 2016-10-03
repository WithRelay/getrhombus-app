# sends email to campaign user list as scheduled
class CampaignJob < ActiveJob::Base
  queue_as :default

  def perform(campaign_id)
    campaign = Campaign.find_by_id(campaign_id)
    if campaign.present?
      campaign.update_attributes(status: 3)
      # TODO task remain to integrate with mandrill for sending emails
    end
  end
end
