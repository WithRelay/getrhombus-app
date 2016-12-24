class SendReminderJob
  @queue = :send_reminders

  def self.perform
    Reminder.recurring.each do |reminder|
      utc_date_time = reminder.date_time.utc
      Resque.enqueue_at_with_queue('campaign', utc_date_time, ReminderJob, reminder.id)
    end
  end
end
