class Alert < ActiveRecord::Base
  belongs_to :user

  attr_accessor :custom_welcome, :phone
  has_one :notification_log, as: :notifiable

  def phone
    self.sms_number
  end
end
