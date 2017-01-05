class MessengerCampaign

  def initialize(campaign)
    @campaign = campaign
    @facebook_messenger = FacebookMessengerService
  end

  def send_campaign
    page_access_token = user_page_access_token
    failure_list = []
    @campaign.lists.each do |list|
      list.get_users.each do |customer|
        @user_fb_creds = customer[:user].fb_creds
        user_fb_cred_id = get_page_specific_id if @user_fb_creds.present?
        send_message = fb_message_sender(page_access_token, user_fb_cred_id)
      failure_list.push(customer[:user]) unless send_message && list.channel.present?
      end
    end
    return failure_list
  end

 private

  def get_page_specific_id
    res = nil
    @user_fb_creds.each do |cred|
      page_user = @facebook_messenger.get_user_info(user_page_access_token, cred.page_specific_id)
      res = cred.page_specific_id if page_user
    end
    res
  end

  def send_fb_images(page_token, fb_cred_id)
    @campaign.images.attachment.each do |image|
      @facebook_messenger.send_attachment(page_token, fb_cred_id, 'image', image.avatar.url)
    end
  end

  # get merchant fb pages which are subscribed
  def user_subscribed_pages
    @campaign.user.fb_pages.subscribed
  end

  def user_page_access_token
    subscribed_pages = user_subscribed_pages
    subscribed_pages[0].page_access_token if subscribed_pages.present?
  end

  def fb_message_sender(token, fb_id)
    token_fb_id = (token.present? && fb_id.present?)
    if token_fb_id
      return @facebook_messenger.send_text_message(token, fb_id, @campaign.text)
      send_fb_images(token, fb_id) if @campaign.images.present?
    else
      token_fb_id
    end
  end
end
