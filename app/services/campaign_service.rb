# services that schedule email sending for campaign
class CampaignService < ScheduleService

  def set_background_jobs
    schedule_now_with_date_time(DateTime.now) if check_now?
  end

  private

  def check_now?
    (is_one_time_now? || is_recurring_with_now?)
  end

  def is_one_time_now?
    @object.one_time? && @object.now?
  end

  def is_recurring_with_now?
    @object.recurring? && @object.now?
  end
end
