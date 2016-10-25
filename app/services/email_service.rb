# services that schedule email sending for campaign
class EmailService
  def self.send_campaign(campaign)
    email_list = campaign.lists.map{ |list| {email: list.user.email } if list.user.present? }
    message_hash = { html: campaign.text, to: email_list }
    image_params = campaign_image_params(campaign)
    email_campaign_hash = image_params.present? ? message_hash.merge({ images: image_params }) : message_hash
    EmailingService.send_email_campaign(email_campaign_hash)
  end

  private_class_method

  def self.campaign_image_params(campaign)
    campaign.images.map do |image|
      campaign.text.gsub!(image.avatar.url, "cid:#{c.image_file_name}")
      { type: image.avatar_content_type,
        name: image.avatar_file_name,
        content: Base64.encode64(open(image.avatar.url) { |image| image.read })
      }
    end
  end
end
