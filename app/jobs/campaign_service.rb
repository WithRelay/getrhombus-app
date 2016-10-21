# services that schedule email sending for campaign
class CampaignService < ScheduleService

  def send_now
    schedule_now
  end

  def schedule_in_background
    @job.set(wait_until: @object.date_time).perform_later(@object.id)
  end
end
