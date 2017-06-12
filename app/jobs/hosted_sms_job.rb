class HostedSmsJob

  @queue = :hosted_sms

  def self.perform

    HostedSms.where.not(status: 'Completed').each do |h|
      HostedSmsService.get_status(h)
      if h.status == 'Pending LOA' && !h.status_events[:loa_sent]
        HostedSmsService.request_loa(h)
        h.status_events[:loa_sent] = true
        h.status_events[:loa_sent_at] = Time.now
        h.save
      elsif h.status == 'Completed' && !h.status_events[:completed_notice_sent]
        EmailingService.send_completed_notice(h)
        h.status_events[:completed_notice_sent] = true
        h.status_events[:completed_notice_sent_at] = Time.now
        h.save
      elsif h.status == 'Action Required' && !h.status_events[:action_required_notice_sent]
        EmailingService.send_action_required_notice(h)
        h.status_events[:action_required_notice_sent] = true
        h.status_events[:action_required_notice_sent_at] = Time.now
        h.save
      elsif h.status == 'Failed' && !h.status_events[:failed_notice_sent]
        EmailingService.send_failed_notice(h)
        h.status_events[:failed_notice_sent] = true
        h.status_events[:action_required_notice_sent_at] = Time.now
        h.save
      end
    end
  end

end
