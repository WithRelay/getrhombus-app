class OneTimeReminderJob < ActiveJob::Base
  queue_as :one_time_reminder

  def perform(reminder_id)
    reminder = Reminder.find_by_id(reminder_id)
    ChannelCampaign::SendCampaign.new(reminder).send_channel_campaign if reminder.present?
  end
end
