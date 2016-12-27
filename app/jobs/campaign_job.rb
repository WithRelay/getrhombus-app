# sends email to campaign user list as scheduled
class CampaignJob < ActiveJob::Base
  queue_as :default

  def perform(campaign)
    send_channel_campaign = ChannelCampaign::SendCampaign
    send_channel_campaign.new(campaign).send_channel_campaign
  end
end
