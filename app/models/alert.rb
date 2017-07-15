class Alert < ActiveRecord::Base
  belongs_to :user

  attr_accessor :custom_welcome
  has_many :notification_logs, as: :notifiable
  serialize :sms_numbers, Array
  serialize :emails, Array

end
