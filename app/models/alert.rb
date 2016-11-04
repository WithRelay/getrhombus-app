class Alert < ActiveRecord::Base
  belongs_to :user

  attr_accessor :custom_welcome, :phone
  has_many :notification_logs, as: :notifiable
  
end
