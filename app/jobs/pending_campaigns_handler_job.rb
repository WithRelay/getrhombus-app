class PendingCampaignsHandlerJob

  def self.perform(campaign_id)
    ActiveRecord::Base.clear_active_connections!
    campaign = Campaign.includes(:images, :user, :lists).where(id: campaign_id).first
    ChannelCampaign::SendCampaign.new(campaign).send_channel_campaign if campaign
  end

end
