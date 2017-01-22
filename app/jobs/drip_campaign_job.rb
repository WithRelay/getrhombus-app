class DripCampaignJob

  @queue = :drip_campaigns

  def self.perform
    
    # if we get mysql has gone away errors
    # ActiveRecord::Base.clear_active_connections!
    
    User.where(user_level: 0).each do |user|
      
      time_in_zone = Time.current

      if ((time_in_zone - user.created_at)/1.day).to_i == 2
        EmailingService.send_proactive_support_email(user)
      elsif ((time_in_zone - user.created_at)/1.day).to_i == 4
        EmailingService.schedule_demo_email(user)
      elsif ((time_in_zone - user.created_at)/1.day).to_i == 14
        EmailingService.free_trial_expiration(user)
      elsif ((time_in_zone - user.created_at)/1.day).to_i == 31
        EmailingService.one_month_followup(user)
      elsif ((time_in_zone - user.created_at)/1.day).to_i == 91
        EmailingService.three_month_followup(user)
      elsif ((time_in_zone - user.created_at)/1.day).to_i == 7
        EmailingService.offer_to_help(user)
      end
    end
  end

end