# sends email to campaign user list as scheduled
class SendNowCampaignJob < ActiveJob::Base
  queue_as :send_now_campaign

  def perform(campaign)
    ChannelCampaign::SendCampaign.new(campaign).send_channel_campaign
  end
end
