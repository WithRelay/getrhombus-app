class ChannelJob
  @queue = :campaign

  def self.perform(campaign_id)
    campaign = Campaign.includes([:images, lists:[:user_lists]]).where(id: campaign_id)[0]
    send_channel_campaign = ChannelCampaign::SendCampaign
    send_channel_campaign.new(campaign).send_channel_campaign
  end
end
