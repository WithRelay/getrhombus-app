class Reminder < Campaign

  # Reminder uses the Campaign table. Reminders do not use all attributes that are in campaigns.

  attr_accessor :mc_id

  belongs_to :user
  before_create :set_campaign_type

  private

  def set_campaign_type
    self.campaign_type = Campaign.campaign_types[:reminder_campaign]
  end
end
