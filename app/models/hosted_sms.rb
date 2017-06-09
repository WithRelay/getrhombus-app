class HostedSms < ActiveRecord::Base
  serialize :cc_emails, Array
  serialize :capabilities
end
