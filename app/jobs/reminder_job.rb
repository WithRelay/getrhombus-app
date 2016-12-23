class ReminderJob < ActiveJob::Base
  queue_as :campaign

  def self.perform(reminder_id)
    reminder = Reminder.find_by_id(reminder_id)
    channel_class = ChannelCampaign::SendCampaign.new(reminder)
    campaign_channel = channel_hash[reminder.channel]
    channel_class.send(campaign_channel)
  end

  private_class_method

  def self.channel_hash
    # NOTE: other channel channel like sms is due to add
    { 'facebook_messenger'=> 'send_fb_message_reminder' }
  end
end
