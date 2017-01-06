class RecurringCampaignJob < BaseScheduler::RecurringJob
  @queue = :recurring_campaigns

  def self.perform
    campaigns = Campaign.recurring.active.includes(:user)
    campaigns.each do |campaign|
      Time.zone = campaign.user.time_zone
      campaign_time = Time.current.strftime('%Y/%m/%d ') + campaign.date_time.in_time_zone.strftime("%H:%M")
      dynamic_date_time = Time.parse(campaign_time).utc
      utc_date_time = campaign.send_count > 0 ? dynamic_date_time : campaign.date_time.utc
      Resque.enqueue_at_with_queue('one_time_campaign',
                                    utc_date_time,
                                    OneTimeCampaignJob,
                                    campaign.id) if uncompleted_campaign_present?(campaign) && check_date(campaign)
    end
  end
end
