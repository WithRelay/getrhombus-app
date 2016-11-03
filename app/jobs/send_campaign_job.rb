class SendCampaignJob
  @queue = :send_campaigns

  def self.perform
    campaigns = Campaign.recurring.active.includes([:images, lists:[:user_lists]])
    campaigns.each do |campaign|
      user_date_time = campaign.date_time.in_time_zone(campaign.user.time_zone)
      sending_time = Time.parse(user_date_time.strftime("%I:%M%p")).utc
      Resque.enqueue_at_with_queue('default',
                                    sending_time,
                                    ChannelJob,
                                    campaign.id) if uncompleted_campaign_present?(campaign) && date_campaign(utc_date_time)
    end
  end

  private_class_method

  def self.uncompleted_campaign_present?(campaign)
    campaign.repeat_days == 0 ? true : campaign.repeat_days != campaign.send_count
  end

  def self.date_campaign(date)
    campaign_date = date.strftime("%Y-%m-%d")
    date_today = Time.now.utc.strftime("%Y-%m-%d")
    date_campaign == date_today
  end
end
