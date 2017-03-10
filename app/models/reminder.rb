# NOTE: reminder uses same table as campaign i.e. campaigns
# reminder do not have all attribute that are in camapaign you can see more details in form http://localhost:3000/users/1/reminders/new
class Reminder < Campaign

  attr_accessor :customer_id

  belongs_to :user
  has_many :campaign_lists, foreign_key: 'reminder_id', dependent: :destroy
  # campaign type is set as enum ( 1 refers to reminder_campaign and 0 refers to promoi_campaign)
  before_create :set_campaign_type

  def update_reminder_job
    destroy_campaign_jobs
    enqueue_notification_jobs if active? && is_today_campaign?
  end

  private

  def set_campaign_type
    self.campaign_type = 1
  end
end
