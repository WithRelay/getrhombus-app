# services that schedule email sending for campaign
class EmailService

  def initialize(campaign)
    @campaign = campaign
    @campaign_service = CampaignService.new(@campaign)
  end

  def send_campaign
    @campaign.lists.each do |list|
      @campaign_service.email_list.push({ email: list.user.email })
      @campaign_service.user_id_list.push({ user_id: list.user.id })
    end
    @campaign_service.send_email(email_hash_params)
  end

  private

  def email_hash_params
    image_params = campaign_image_params
    message_hash = { html: @campaign.text, to: @campaign_service.email_list }
    return image_params.present? ? message_hash.merge({ images: image_params }) : message_hash
  end

  def campaign_image_params
    @campaign.images.map do |image|
      @campaign.text.gsub!(image.avatar.url, "cid:#{image.avatar_file_name}")
      { type: image.avatar_content_type,
        name: image.avatar_file_name,
        content: Base64.encode64(open(image.avatar.url) { |image| image.read })
      }
    end
  end
end
