class Alert < ActiveRecord::Base
  belongs_to :user

  attr_accessor :custom_welcome, :phone
  has_many :notification_logs, as: :notifiable

  def phone
    self.sms_number
  end

  # Because empty should save as nil
  def sms_number=(v)
    write_attribute(:sms_number, v.present? ? v : nil)
  end  
end
