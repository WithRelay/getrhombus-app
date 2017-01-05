# sends email to campaign user list as scheduled
class SendNowCampaignJob < ActiveJob::Base
  queue_as :send_now_campaign

  def perform(campaign_id)
    campaign = Campaign.find_by_id(campaign_id)
    ChannelCampaign::SendCampaign.new(campaign).send_channel_campaign if campaign.present?
  end
end
