class EmailCampaign

    def initialize(campaign)
      @campaign = campaign
    end

    def user_email_list
      email_list = []
      @campaign.lists.each do |list|
        list.get_users.each{ |customer| email_list.push({ email: customer[:user].email }) }
      end
      email_list
    end

    def send_campaign
      EmailingService.send_email_campaign(email_hash_params)
    end

    private

    def email_hash_params
      message_hash = { html: @campaign.text, subject: @campaign.subject, to: user_email_list }
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
      @campaign.images.attachment.map{ |image| create_image_params(image) }
    end

    def create_image_params(image)
      {
        type: image.avatar_content_type,
        name: image.avatar_file_name,
        content: Base64.encode64(open(image.avatar.url){ |image| image.read })
      }
    end
end
