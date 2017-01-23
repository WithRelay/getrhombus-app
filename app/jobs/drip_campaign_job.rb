class DripCampaignJob

  @queue = :drip_campaigns

  def self.perform
    
    # if we get mysql has gone away errors
    # ActiveRecord::Base.clear_active_connections!
   
    User.where(user_level: 0).each do |user|

      diff_in_days = (((Time.current.change(hours: 0) - user.created_at.change(hour: 0)) / 1.day).to_i) - 1

      if diff_in_days == 2
        EmailingService.send_proactive_support_email(user)
      elsif diff_in_days == 4
        EmailingService.schedule_demo_email(user)
      # Customer Import & Campaigns (5 days after sign-up)
      elsif diff_in_days == 5
        EmailingService.customer_import_campaigns(user)
      elsif diff_in_days == 7
        EmailingService.offer_to_help(user)
      # Connect Facebook Messenger (9 days after sign-up)
      elsif diff_in_days == 9
        EmailingService.connect_facebook_messenger(user)
      # Add Bank Account (12 days after sign-up)
      elsif diff_in_days == 12
        EmailingService.add_bank_account(user)
      elsif diff_in_days == 14
        EmailingService.free_trial_expiration(user)
      # Lists (18 days after sign-up)
      elsif diff_in_days == 18
        EmailingService.lists(user)
      # Customer Segmentation (24 days after sign-up)
      elsif diff_in_days == 24
        EmailingService.customer_segmentation(user)
      # In-Chat Payments (30 days after sign-up)
      elsif diff_in_days == 30
        EmailingService.in_chat_payments(user)
      elsif diff_in_days == 31
        EmailingService.one_month_followup(user)
      # Virtual Terminal - Charge/Pre-authorize Transactions (36 days after sign-up)
      elsif diff_in_days == 36
        EmailingService.pre_authorize_transactions(user)
      # Plans & Subscriptions (42 days after sign-up)
      elsif diff_in_days == 42
        EmailingService.plans_and_subscriptions(user)
      # Saved Replies (50 days)
      elsif diff_in_days == 50
        EmailingService.saved_replies(user)
      # Message Reason (57 days)
      elsif diff_in_days == 57
        EmailingService.message_reason(user)
      # Campaign Templates (64 days)
      elsif diff_in_days == 64
        EmailingService.campaign_templates(user)
      # Set Customer Notifications (74 days)
      elsif diff_in_days == 74
        EmailingService.set_customer_notifications(user)
      # Hashtags/Keywords (84 days)
      elsif diff_in_days == 84
        EmailingService.hashtag_keywords(user)
      elsif diff_in_days == 91
        EmailingService.three_month_followup(user)
      # First-time Message Auto-response (100 days)
      elsif diff_in_days == 100
        EmailingService.first_time_message_auto_response(user)
      end
      
    end

  end

end