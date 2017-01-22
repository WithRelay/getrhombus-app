class DripCampaignJob

  @queue = :drip_campaigns

  def self.perform
    
    # if we get mysql has gone away errors
    # ActiveRecord::Base.clear_active_connections!
    
    User.where(user_level: 0).each do |user|
      
      time_in_zone = Time.current

      if (time_in_zone - user.created_at).round/(60*60*24) == 2 # days
        EmailingService.send_proactive_support_email(user)
      elsif (time_in_zone - user.created_at).round/(60*60*24) == 4 # days
        EmailingService.schedule_demo_email(user)
      elsif (time_in_zone - user.created_at).round/(60*60*24) == 14 # days
        EmailingService.free_trial_expiration(user)
      elsif (time_in_zone - user.created_at).round/(60*60*24) == 31 # days
        EmailingService.one_month_followup(user)
      elsif (time_in_zone - user.created_at).round/(60*60*24) == 91 # days
        EmailingService.three_month_followup(user)
      elsif (time_in_zone - user.created_at).round/(60*60*24) == 7 # days
        EmailingService.offer_to_help(user)
      end
    end
  end

end