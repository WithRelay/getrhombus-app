# BaseScheduler::RecurringJob holds common behaviour for all background jobs.
module BaseScheduler
  class RecurringJob

    private_class_method

    # checks data of campaign by comparing campaign's date and returns boolean
    def self.check_date(campaign)
      # sets time zone i.e. user time zone for all datatime object
      Time.zone = campaign.user.time_zone
      # set current date time in campaign user's time zone
      date_time_now =  Time.now.in_time_zone
      # check if job is already send to rescue scheduler job_schedule variable contains boolean value
      job_schedule = Resque.find_delayed_selection{|s| s.include?(campaign.id) }
      # if campaign is less than send_count than 1. it means it is running first time
      if campaign.send_count < 1
        # set campaign date_time to users time zone
        date_time_campaign = campaign.date_time.in_time_zone
        # check campaign job is present or not if it is already present no need to rescheule
        # if it is not present caompares current time and return boolean
        job_schedule.present? ? false : date_time_now <= date_time_campaign
      elsif campaign.date_time <= Time.current
        campaign_time = Time.current.strftime('%Y-%m-%d ') + campaign.date_time.in_time_zone.strftime("%H:%M")
        dynamic_date_time = Time.parse(campaign_time).in_time_zone
        job_schedule.present? ? false : date_time_now <= dynamic_date_time
      end
    end

    def self.uncompleted_campaign_present?(campaign)
      campaign.repeat_days == 0 ? true : campaign.repeat_days != campaign.send_count
    end
  end
end
