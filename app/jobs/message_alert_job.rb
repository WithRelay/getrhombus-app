class MessageAlertJob
  @queue = :message_alerts

  def self.perform
    begin
      # if we get mysql has gone away errors
      # ActiveRecord::Base.clear_active_connections!
    
      # Add FB messages here
      results =  Alert.select('alerts.id as id, u.email, u.rhombus_number, sms_number, include_sms, alerts.interval')
                 .joins('INNER JOIN users u on alerts.user_id = u.id')
                 .where('alerts.send_alert = 1')

      results.each do |r|
        # Using utc but it doesn't matter since
        # Default zone is ET so notification_log is saved from ET to UTC and Time.current is ET

        last_notification = r.notification_logs.last

        time_diff = !last_notification || Time.current - last_notification.created_at

        if (last_notification == nil) || (time_diff >= (r.interval * 60).to_f)

          messages = Message.where(to: r.rhombus_number, unread: true, unread_notification_sent: false)

          if messages.present?
            pluralize_msg = "message".pluralize(messages.length) 
                   
            EmailingService.send_unread_message_alert({ unread_count: messages.length, to: r.email, pluralize_msg: pluralize_msg })
            r.notification_logs.create(notify_type: 'new_alert', channel: 'Email', reason: 'unread_messages')

            if r.include_sms && r.sms_number.present?
              platform_number = User.find_by(email: Rails.application.secrets.team_email).rhombus_number
              msg = Message.new
              msg_to_send = "Rhombus Notification: You have #{messages.length} new unread " + pluralize_msg + " on your dashboard."
              msg.send_and_save_message(31, platform_number, r.sms_number, msg_to_send)
              msg.update(unread: false, unread_notification_sent: true)
              r.notification_logs.create(notify_type: 'new_alert', channel: 'Message', channel_id: msg.id, reason: 'unread_messages')
            end 

            # CHANGE - This should only happen if messages/emails return true...maybe only message
            messages.update_all(unread_notification_sent: true)
          end
        end  
        
      end
    rescue StandardError => e
      # Notify team of failed job
    end
  end

end