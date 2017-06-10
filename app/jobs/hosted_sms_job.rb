class HostedSmsJob

  @queue = :hosted_sms

  def self.perform

    # if we get mysql has gone away errors
    #ActiveRecord::Base.clear_active_connections!

    HostedSms.all.each do |h|
      # time.now.in_time_zone format year month is > card date then notify
      unless h.status == 'Completed' || h.status == 'Failed'
        HostedSmsService.get_status(h)
      elsif h.status == 'Received' && !h.signing_document_sid
        HostedSmsService.request_loa(h)
      end
    end
  end

end
