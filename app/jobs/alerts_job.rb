class AlertsJob
	@queue = :alerts

	def self.perform
    # if we get mysql has gone away errors
    # ActiveRecord::Base.clear_active_connections!
  
    # Add FB messages here
    results = Alert.select('alerts.id as id, u.email, count(*) as unread_count, sms_number, include_sms, last_alert_sent_at, alerts.interval')
             .joins('INNER JOIN users u on alerts.user_id = u.id')
             .joins('INNER JOIN messages m on m.to = u.rhombus_number')
             .where('m.unread = 1 and alerts.send_alert = 1')
             .group('m.to')

    results.each do |r|

      if (Time.current - r.last_alert_sent_at) >= (r.interval * 60).to_f
        EmailingService.send_unread_message_alert(r)
        if r.include_sms
          #Message.send_and_save_message()
        end
      end     

      r.update_attribute(:last_alert_sent_at, Time.current)
	  end
  end


end