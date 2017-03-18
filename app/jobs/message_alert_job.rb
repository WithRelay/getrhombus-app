class MessageAlertJob
  @queue = :message_alerts

  def self.perform
    begin
      # if we get mysql has gone away errors
      # ActiveRecord::Base.clear_active_connections!
    
      # Add FB messages here
      results =  Alert.select('alerts.id as id, alert.user_id, u.email, u.rhombus_number, u.rn_type, sms_number, include_sms, alerts.interval, u.time_zone')
                 .joins('INNER JOIN users u on alerts.user_id = u.id')
                 .where('alerts.send_alert = 1')

      results.each do |r|
        # Using utc but it doesn't matter since
        # Default zone is ET so notification_log is saved from ET to UTC and Time.current is ET

        last_notification = r.notification_logs.last

        time_diff = !last_notification || Time.current - last_notification.created_at

        if (last_notification == nil) || (time_diff >= (r.interval * 60).to_f)

          conv_refs = ConversationRef.get_merchant_total_unread_messages_not_notified(r.user_id)
          
          if conv_refs.present?
            pluralize_msg = "message".pluralize(conv_refs.length) 



            # build data set of up to 3 messages that will be used to fill the template
            # For each, convert time to merchant timezone before formatting
            received_at = conv_refs.first.created_at.in_time_zone(r.time_zone)
            # send_unread_message_alert method needs to change
            EmailingService.send_unread_message_alert({ unread_count: conv_refs.length, to: r.email, pluralize_msg: pluralize_msg })




            # You should need to touch anything below here
            r.notification_logs.create(notify_type: 'new_alert', channel: 'Email', reason: 'unread_messages')
            if r.include_sms && r.sms_number.present?
              platform = User.get_platform_acct_obj              
              msg_to_send = "Relay Notification: You have #{conv_refs.length} new unread " + pluralize_msg + " on your dashboard."              
              re = Conversation.find_or_create_conversation_for_message_and_send_publish(platform, nil, 'phone_number', r.sms_number, msg_to_send, 'Message')
              if re
                r.notification_logs.create(notify_type: 'new_alert', channel: 'Message', channel_id: re, reason: 'unread_messages')
              end
            end 

            # CHANGE - This should only happen if messages/emails return true...maybe only message
            conv_refs.update_all(unread_notification_sent: true)
          end

        end        
      end
    rescue StandardError => e
      # Notify team of failed job
    end
  end

end