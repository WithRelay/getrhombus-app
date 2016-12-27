class RecurringCampaignJob
  @queue = :recurring_campaigns

  def self.perform
    campaigns = Campaign.recurring.active.includes([:images, lists:[:user_lists]])
    campaigns.each do |campaign|
      utc_date_time = campaign.date_time.utc
      Resque.enqueue_at_with_queue('one_time_campaign',
                                    utc_date_time,
                                    OneTimeCampaignJob,
                                    campaign.id) if uncompleted_campaign_present?(campaign) && check_date(campaign)
    end
  end

  private_class_method

  def self.check_date(campaign)
    Time.zone = campaign.user.time_zone
    date_campaign = Time.zone.parse(campaign.date_time.strftime("%Y-%m-%d"))
    current_time = Time.current
    date_today =  Time.zone.parse(current_time.strftime("%Y-%m-%d"))
    return date_today >= date_campaign
  end

  def self.uncompleted_campaign_present?(campaign)
    campaign.repeat_days == 0 ? true : campaign.repeat_days != campaign.send_count
  end
end
