class Reminderjob < ActiveJob::Base
  queue_as :campaign

  def self.perform(reminder_id)
    reminder = Reminder.find_by_id(reminder_id)
    channel_class = channel_hash[campaign.channel].constantize
    channel_class.send_campaign(reminder)
  end

  private_class_method

  def self.channel_hash
    { 'sms'=>'SmsService', 'facebook_messenger'=>'FacebookMessengerService' }
  end
end
