# This class is only responsible for sending campaign via email channel.
class EmailCampaign

  def initialize(campaign, user_list=[])
    @campaign = campaign # campaign object
    @user_list = user_list
    @email_list
  end

  def send_campaign
    # class method send_email_campaign accepts hash parameter
    EmailingService.send_email_campaign(email_hash_params.merge({ to: user_email_list }))
  end

  def send_failure
    EmailingService.send_email_campaign(email_hash_params.merge({ to: failure_email_list }))
  end

  private

  def failure_email_list
    @user_list.each do |user|
      @email_list.push({ email: user.email })
    end
    @email_list
  end

  # returns array of user email list eg: [{ email: '<redacted_email>' }, { email: '<redacted_email>' }]
  def user_email_list
    unless @campaign.test?
      @campaign.lists.each do |list|
        list.get_users.each{ |customer| @email_list.push({ email: customer[:user].email }) }
      end
    else
      email_list.push({ email: @campaign.user.email })
    end
    return @email_list
  end

  # returns default hash as { html: '', subject: '', to: [{email: '<redacted_email>'}]
  # if inline image  and attachment image is present return with merging both hash
  def email_hash_params
    message_hash = { html: @campaign.text, subject: @campaign.subject}
    message_hash.merge!({ images: inline_images }) if inline_images.present?
    message_hash.merge!({ attachments: attachment_images }) if attachment_images.present?
    return message_hash
  end

  # retuns [ { type: image_content_type, name: image_name,  content: Base64.encode64 } ]
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
