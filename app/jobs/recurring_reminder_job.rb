class RecurringReminderJob
  @queue = :recurring_reminders

  def self.perform
    Reminder.recurring.each do |reminder|
      utc_date_time = reminder.date_time.utc
      Resque.enqueue_at_with_queue('one_time_reminder', utc_date_time, OneTimeReminderJob, reminder.id)
    end
  end
end
