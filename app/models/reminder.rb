class Reminder < Campaign
  belongs_to :user
  before_create :set_campaign_type

  private

  def set_campaign_type
    self.campaign_type = 1
  end
end
