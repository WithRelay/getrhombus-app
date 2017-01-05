class OneTimeCampaignJob
  @queue = :one_time_campaign

  def self.perform(campaign_id)
    campaign = Campaign.includes([:images, lists:[:user_lists]]).where(id: campaign_id)[0]
    ChannelCampaign::SendCampaign.new(campaign).send_channel_campaign
  end
end
