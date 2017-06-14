class HostedSms < ActiveRecord::Base
  belongs_to :user
  serialize :cc_emails, Array
  serialize :capabilities
  serialize :status_events

  #  Letter of Authorization (LOA) document the user needs to sign.
  scope :unsigned, -> { where(signing_document_sid: nil) }
  #Status:[Received, Pending LOA, Carrier Processing, Completed, Action Required, Failed]
  scope :not_completed, -> { where("status != ? OR status IS ?", "Completed", nil) }
end
