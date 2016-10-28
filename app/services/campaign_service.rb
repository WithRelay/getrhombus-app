# campaign service class for building campaign with use list
class CampaignService
  attr_accessor :user_id_list, :email_list

  def initialize(campaign)
    @user_id_list = []
    @email_list = []
    @campaign = campaign
  end

  def send_email(email_hash)
    update_campaign if EmailingService.send_email_campaign(email_hash)
  end

  def update_campaign
    @campaign.send_count = @campaign.send_count + 1
    @campaign.lists.each { |list| @campaign.campaign_user_lists.build(@user_id_list) }
    @campaign.save(validate: false)
    @campaign.update_attribute('status', 3) if is_recurring_campaign_completed? || @campaign.one_time?
  end

  def is_recurring_campaign_completed?
    @campaign.repeat_days == @campaign.send_count if @campaign.recurring?
  end
end
