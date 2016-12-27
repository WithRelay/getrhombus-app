class MessengerCampaign

  def initialize(campaign)
    @campaign = campaign
    @facebook_messenger = FacebookMessengerService
  end

  def send_campaign
    page_access_token = user_page_access_token
    @campaign.lists.each do |list|
     list.get_users.each do |customer|
       user_fb_cred = customer[:user].fb_cred
       user_fb_cred_id = user_fb_cred.page_specific_id if user_fb_cred.present?
       fb_message_sender(page_access_token, user_fb_cred_id)
     end
   end if @campaign.lists.present?
  end

 private

  def send_fb_images(page_token, fb_cred_id)
    @campaign.images.each do |image|
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
      @facebook_messenger.send_text_message(token, fb_id, @campaign.text)
      send_fb_images(token, fb_id) if @campaign.images.present?
    else
      token_fb_id
    end
  end
end
