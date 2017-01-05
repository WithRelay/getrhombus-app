class RecurringJob

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
