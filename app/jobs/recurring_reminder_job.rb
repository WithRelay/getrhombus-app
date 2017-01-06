class RecurringReminderJob < BaseScheduler::RecurringJob
  @queue = :recurring_reminders

  def self.perform
    Reminder.recurring.includes(:user).each do |reminder|
      Time.zone = reminder.user.time_zone
      reminder_time = Time.current.strftime('%Y/%m/%d ') + reminder.date_time.in_time_zone.strftime("%H:%M")
      dynamic_date_time = Time.parse(reminder_time).utc
      utc_date_time = reminder.send_count > 0 ? dynamic_date_time : reminder.date_time.utc
      Resque.enqueue_at_with_queue('one_time_reminder', utc_date_time,
                                    OneTimeReminderJob, reminder.id) if check_date(reminder)
    end
  end
end
