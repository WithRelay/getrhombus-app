# sends email to campaign user list as scheduled
class CampaignJob < ActiveJob::Base
  queue_as :default

  def perform(campaign_id)
    campaign = Campaign.find_by_id(campaign_id)
    if campaign.present?
      campaign.update_attributes(status: 3)
      email_list = campaign.lists.map{ |list| {email: list.user.email } if list.user.present? }
      image_params = campaign.images.map{ |image|  if image.avatar.present?
                                                    { type: image.avatar_content_type,
                                                      name: image.avatar_file_name,
                                                      content: Base64.encode64(open(image.avatar.url) { |image| image.read }) }
                                                    end
                                                    }
      EmailingService.send_email_campaign({ html: campaign.text, to: email_list }) if email_list.present?
    end
  end
end
