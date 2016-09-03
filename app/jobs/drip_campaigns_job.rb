class DripCampaignsJob

  @queue = :drip_campaigns

  def self.perform
    
    # if we get mysql has gone away errors
    # ActiveRecord::Base.clear_active_connections!
    
    User.where(user_level: 0).each do |user|
      
      time_in_zone = Time.zone.now

      if (time_in_zone - user.created_at) <= 3.days.seconds.to_f
        EmailingService.send_founder_welcome_email(user.email)
      elsif (time_in_zone - user.created_at) <= 7.days.seconds.to_f
        EmailingService.send_proactive_support_email(user.email)
      elsif (time_in_zone - user.created_at) <= 10.days.seconds.to_f
        EmailingService.schedule_demo_email(user.email)
      end
    end
  end

end