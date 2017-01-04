class RecurringCampaignJob
  @queue = :recurring_campaigns

  def self.perform
    campaigns = Campaign.recurring.active.includes(:user)
    campaigns.each do |campaign|
      Time.zone = campaign.user.time_zone
      campaign_time = campaign.date_time.in_time_zone.strftime("%H:%M") + campaign.date_time.in_time_zone.strftime("%H:%M")
      dynamic_date_time = Time.parse(campaign_time).utc
      utc_date_time = campaign.send_count > 0 ? dynamic_date_time : campaign.date_time.utc
      Resque.enqueue_at_with_queue('one_time_campaign',
                                    utc_date_time,
                                    OneTimeCampaignJob,
                                    campaign.id) if uncompleted_campaign_present?(campaign) && check_date(campaign)
    end
  end

  private_class_method

  def self.check_date(campaign)
    Time.zone = campaign.user.time_zone
    date_time_now =  Time.now.in_time_zone
    job_schedule = Resque.find_delayed_selection{|s| s.include?(campaign.id) }
    if campaign.send_count < 1
      date_time_campaign = campaign.date_time.in_time_zone
      job_schedule.present? ? false : date_time_now <= date_time_campaign
    else
      campaign_time = Time.current.strftime('%Y-%m-%d ') + campaign.date_time.in_time_zone.strftime("%H:%M")
      dynamic_date_time = Time.parse(campaign_time).in_time_zone
      job_schedule.present? ? false : date_time_now <= dynamic_date_time
    end
  end

  def self.uncompleted_campaign_present?(campaign)
    campaign.repeat_days == 0 ? true : campaign.repeat_days != campaign.send_count
  end
end
