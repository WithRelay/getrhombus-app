class ChannelJob
  @queue = :send_email

  def self.perform
    Campaign.recurring.active.each do |campaign|
      utc_date_time = campaign.date_time.in_time_zone(campaign.user.time_zone).utc
      CampaignJob.set(wait_until: utc_date_time).perform_later(campaign.id)
    end if campaign.present?
  end
end
