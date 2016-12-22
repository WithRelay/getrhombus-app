class NotificationLog < ActiveRecord::Base

  belongs_to :notifiable, :polymorphic => true
  belongs_to :message
  # channel, channel_id - for the models used to send the notifications
  # notifiable, notifiable_type are the models issuing the notifications
  
end