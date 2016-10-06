# sends email to campaign user list as scheduled
class CampaignJob < ActiveJob::Base
  queue_as :default

  def perform(campaign_id)
    campaign = Campaign.find_by_id(campaign_id)
    if campaign.present?
      campaign.update_attributes(status: 3)
      email_list = Campaign.first.lists.map{|list| {email: list.user.email } if list.user.present? }
      EmailingService.send_email_campaign({ html: campaign.text, to: email_list }) if email_list.present?
    end
  end
end
