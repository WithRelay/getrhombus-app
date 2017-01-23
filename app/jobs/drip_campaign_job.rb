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
      # Customer Import & Campaigns (5 days after sign-up)
      elsif ((time_in_zone - user.created_at)/1.day).to_i == 5
        EmailingService.customer_import_campaigns(user)
      elsif ((time_in_zone - user.created_at)/1.day).to_i == 7
        EmailingService.offer_to_help(user)
      # Connect Facebook Messenger (9 days after sign-up)
      elsif ((time_in_zone - user.created_at)/1.day).to_i == 9
        EmailingService.connect_facebook_messenger(user)
      # Add Bank Account (12 days after sign-up)
      elsif ((time_in_zone - user.created_at)/1.day).to_i == 12
        EmailingService.add_bank_account(user)
      elsif ((time_in_zone - user.created_at)/1.day).to_i == 14
        EmailingService.free_trial_expiration(user)
      # Lists (18 days after sign-up)
      elsif ((time_in_zone - user.created_at)/1.day).to_i == 18
        EmailingService.lists(user)
      # Customer Segmentation (24 days after sign-up)
      elsif ((time_in_zone - user.created_at)/1.day).to_i == 24
        EmailingService.customer_segmentation(user)
      # In-Chat Payments (30 days after sign-up)
      elsif ((time_in_zone - user.created_at)/1.day).to_i == 30
        EmailingService.in_chat_payments(user)
      elsif ((time_in_zone - user.created_at)/1.day).to_i == 31
        EmailingService.one_month_followup(user)
      # Virtual Terminal - Charge/Pre-authorize Transactions (36 days after sign-up)
      elsif ((time_in_zone - user.created_at)/1.day).to_i == 36
        EmailingService.pre_authorize_transactions(user)
      # Plans & Subscriptions (42 days after sign-up)
      elsif ((time_in_zone - user.created_at)/1.day).to_i == 42
        EmailingService.plans_and_subscriptions(user)
      # Saved Replies (50 days)
      elsif ((time_in_zone - user.created_at)/1.day).to_i == 50
        EmailingService.saved_replies(user)
      # Message Reason (57 days)
      elsif ((time_in_zone - user.created_at)/1.day).to_i == 57
        EmailingService.message_reason(user)
      # Campaign Templates (64 days)
      elsif ((time_in_zone - user.created_at)/1.day).to_i == 64
        EmailingService.campaign_templates(user)
      # Set Customer Notifications (74 days)
      elsif ((time_in_zone - user.created_at)/1.day).to_i == 74
        EmailingService.set_customer_notifications(user)
      # Hashtags/Keywords (84 days)
      elsif ((time_in_zone - user.created_at)/1.day).to_i == 84
        EmailingService.hashtag_keywords(user)
      elsif ((time_in_zone - user.created_at)/1.day).to_i == 91
        EmailingService.three_month_followup(user)
      # First-time Message Auto-response (100 days)
      elsif ((time_in_zone - user.created_at)/1.day).to_i == 100
        EmailingService.first_time_message_auto_response(user)
      end
    end
  end

end