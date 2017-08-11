class HostedSmsJob

  @queue = Rails.env + "_hosted_sms"

  def self.perform
    ActiveRecord::Base.clear_active_connections!

    HostedSms.includes(:user).not_completed.each do |h|
      HostedSmsService.get_status(h)
      if h.status.casecmp('pending-loa').zero? && !h.status_events[:loa_sent]
        HostedSmsService.request_loa(h)
        h.status_events[:loa_sent] = true
        h.status_events[:loa_sent_at] = Time.now
        h.save
      elsif h.status.casecmp('completed').zero? && !h.status_events[:completed_notice_sent]
        break if h.user.rhombus_number.nil?
        break unless TextingService.release_number(h.user.rhombus_number)
        EmailingService.send_completed_notice(h.user)
        h.user.update_rhombus_number(h.phone_number)
        h.status_events[:completed_notice_sent] = true
        h.status_events[:completed_notice_sent_at] = Time.now
        h.save
      elsif h.status.casecmp('action-required').zero? && !h.status_events[:action_required_notice_sent]
        EmailingService.send_action_required_notice(h.user)
        h.status_events[:action_required_notice_sent] = true
        h.status_events[:action_required_notice_sent_at] = Time.now
        h.save
      elsif h.status.casecmp('failed').zero? && !h.status_events[:failed_notice_sent]
        EmailingService.send_failed_notice(h.user)
        h.status_events[:failed_notice_sent] = true
        h.status_events[:failed_notice_sent_at] = Time.now
        h.save
      end
    end
  end
end
