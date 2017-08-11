# Alert
class Alert < ActiveRecord::Base
  belongs_to :user

  attr_accessor :custom_welcome
  serialize :sms_numbers, Array
  serialize :emails, Array
end
