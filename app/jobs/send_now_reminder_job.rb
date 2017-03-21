# sends email to campaign user list as scheduled
class SendNowCampaignJob < ApplicationJob
  queue_as :send_now_reminder

  def perform(campaign_id)
    campaign = Reminder.find_by_id(campaign_id)
    ChannelCampaign::SendCampaign.new(campaign).send_channel_campaign if campaign.present?
  end
end
