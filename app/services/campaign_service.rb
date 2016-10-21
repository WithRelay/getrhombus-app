# services that schedule email sending for campaign
class CampaignService < ScheduleService
  def send_now
    schedule_now
  end
end
