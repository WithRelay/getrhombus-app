class EmailCampaign

  def initialize(campaign, recipients)
    @campaign = campaign
    @recipients = recipients
  end

  def send_campaign
    EmailingService.send_email_campaign(email_hash_params.merge({ to: email_list }), !@campaign.test?)
    { recipients: @recipients }
  end

  private 

  def email_list
    return [{ email: @campaign.user.email }] if @campaign.test?
    user_ids = @recipients.map { |recipient| recipient.customer_id }
    User.where(id: user_ids).pluck(:email).map { |email| { email: email } }      
  end

  # returns default hash as { html: '', subject: '', to: [{email: '<redacted_email>'}]
  # if inline image  and attachment image is present return with merging both hash
  def email_hash_params
    inlined_images = inline_images
    attached_images = @campaign.images.attachment.map{ |image| create_image_params(image) }

    message_hash = { headers: { "Reply-To" => @campaign.user.email },
                     html: @campaign.text, from_name: @campaign.user.user_title,
                     subject: @campaign.subject.present? ? @campaign.subject : "Message from #{@campaign.user.org_name}" }
    message_hash.merge!({ images: inlined_images }) if inlined_images.present?    
    message_hash.merge!({ attachments: attached_images }) if attached_images.present?
    
    return message_hash
  end

  # retuns [ { type: image_content_type, name: image_name,  content: Base64.encode64 } ]
  def inline_images
    @campaign.images.inline.map do |image|
      @campaign.text.gsub(image.avatar.url, "cid:#{image.avatar_file_name}")
      create_image_params(image)
    end
  end

  def create_image_params(image)
    {
      type: image.avatar_content_type, name: image.avatar_file_name,
      content: Base64.encode64(open(image.avatar.url){ |image| image.read })
    }
  end
end
