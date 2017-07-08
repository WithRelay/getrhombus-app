class SendNowCampaignJob < ApplicationJob
  
  def perform(campaign_id, is_reminder)
    campaign = Campaign.includes(:images, :user, :lists).find_by_id(campaign_id)
    ChannelCampaign::SendCampaign.new(campaign).send_channel_campaign if campaign
  end
end
