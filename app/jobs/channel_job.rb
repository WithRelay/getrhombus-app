class ChannelJob
  @queue = :send_email

  def self.perform
    campaign = Campaign.recurring
    campaign.all.each do |campaign|
      CampaignService.new(campaign).schedule_in_background
    end if campaign.present?
  end
end
