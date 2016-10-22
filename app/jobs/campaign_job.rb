# sends email to campaign user list as scheduled
class CampaignJob < ActiveJob::Base
  queue_as :default

  def perform(campaign_id)
    campaign = Campaign.find_by_id(campaign_id)
    if campaign.present?
      email_list = campaign.lists.map{ |list| {email: list.user.email } if list.user.present? }
      message_hash = { html: campaign.text, to: email_list }
      email_campaign_hash = campaign_image_params.present? ? message_hash.merge({ images: campaign_image_params }) : message_hash
      EmailingService.send_email_campaign(email_campaign_hash)
    end
  end

  def campaign_image_params(campaign)
    campaign.images.map do |image|
      campaign.text.gsub!(image.avatar.url, "cid:#{c.image_file_name}")
      { type: image.avatar_content_type,
        name: image.avatar_file_name,
        content: Base64.encode64(open(image.avatar.url) { |image| image.read })
      }
  end
end
