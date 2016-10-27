class SendCampaignJob
  @queue = :send_campaigns

  def self.perform
    recurring_active_campaign = Campaign.recurring.active
    recurring_active_campaign.each do |campaign|
      utc_date_time = campaign.date_time.in_time_zone(campaign.user.time_zone).utc
      Resque.enqueue_at_with_queue('default', utc_date_time, ChannelJob, campaign.id)
    end if recurring_active_campaign.present?
  end
end
