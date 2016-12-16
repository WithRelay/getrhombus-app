# services that schedule email sending for campaign
module SendEmail
  class EmailCampaign

    def initialize(campaign)
      @campaign = campaign
      @campaign_service = ChannelCampaign::SendCampaign.new(@campaign)
    end

    def send_campaign
      @campaign.lists.each do |list|
        list.user_lists.each do |customer|
          @campaign_service.email_list.push({ email: customer.user.email })
          @campaign_service.user_id_list.push({ user_id: customer.user.id })
        end
      end
      @campaign_service.send_email(email_hash_params)
    end

    private

    def email_hash_params
      message_hash = { html: @campaign.text, subject: @campaign.subject, to: @campaign_service.email_list }
      message_hash.merge!({ images: inline_images }) if inline_images.present?
      message_hash.merge!({ attachments: attachment_images }) if attachment_images.present?
      return message_hash
    end

    def inline_images
      @campaign.images.inline.map do |image|
        @campaign.text.gsub!(image.avatar.url, "cid:#{image.avatar_file_name}")
        create_image_params(image)
      end
    end

    def attachment_images
      @campaign.images.attachment.map do |image|
        create_image_params(image)
      end
    end

    def create_image_params(image)
      { type: image.avatar_content_type,
        name: image.avatar_file_name,
        content: Base64.encode64(open(image.avatar.url) { |image| image.read })
      }
    end
  end
end
