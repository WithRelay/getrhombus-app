class Alert < ActiveRecord::Base
  belongs_to :user

  attr_accessor :custom_welcome, :phone

  def phone
    self.sms_number
  end
end
