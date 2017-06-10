class HostedSms < ActiveRecord::Base
  serialize :cc_emails, Array
  serialize :capabilities

  #  Letter of Authorization (LOA) document the user needs to sign.
  scope :unsigned, -> { where(signing_document_sid: nil) }
  #Status:[Received, Pending LOA, Carrier Processing, Completed, Action Required, Failed]
end
