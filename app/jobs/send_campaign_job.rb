class SendCampaignJob
  @queue = :send_campaigns

  def self.perform
    campaigns = Campaign.recurring.active.includes([:images, lists:[:user_lists]])
    campaigns.each do |campaign|
      utc_date_time = campaign.date_time.in_time_zone(campaign.user.time_zone).utc
      Resque.enqueue_at_with_queue('default',
                                    utc_date_time,
                                    ChannelJob,
                                    campaign.id) if uncompleted_campaign_present?(campaign)
    end if campaigns.present?
  end

  private_class_method

  def self.uncompleted_campaign_present?(campaign)
    campaign.repeat_days == 0 ? true : campaign.repeat_days != campaign.send_count
  end
end
