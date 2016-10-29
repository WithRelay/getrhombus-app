class MessageAlertJob
	@queue = :message_alerts

	def self.perform
    # if we get mysql has gone away errors
    # ActiveRecord::Base.clear_active_connections!
  
    # Add FB messages here
    results = Alert.includes(:notification_log).select('alerts.id as id, u.email, u.time_zone, count(*) as unread_count, sms_number, include_sms, alerts.interval')
             .joins('INNER JOIN users u on alerts.user_id = u.id')
             .joins('INNER JOIN messages m on m.to = u.rhombus_number')
             .where('m.unread = 1 and alerts.send_alert = 1')
             .group('m.to')

    results.each do |r|

      if r.notification_log.present? || ((Time.current - r.notification_log.updated_at) >= (r.interval * 60).to_f)
        EmailingService.send_unread_message_alert(r)

        # need to check that number is valid???
        Message.send_and_save_message() if r.include_sms
        time = Time.now.in_zone(r.time_zone)
        if r.notification_log
          r.notification_log.updated_at = time
        else
          r.notification_log = NotificationLog.create(created_at: time, updated_at: time, notify_type: 'new_alert', channel: 'email', reason: 'unread_messages')
        end           
      end

	  end
  end


end