# services that schedule email sending for campaign
class CampaignService < ScheduleService

  def send_now
    schedule_now
  end

  def schedule_in_background
    utc_date_time = @object.date_time(@object.user.time_zone).utc
    @job.set(wait_until: utc_date_time).perform_later(@object.id)
  end
end
