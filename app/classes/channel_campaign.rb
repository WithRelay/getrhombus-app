# Campaign service class for building campaign with use list
module ChannelCampaign
  class SendCampaign

    def initialize(campaign)
      @campaign = campaign
      @facebook_messenger = FacebookMessengerService
    end

    def get_user_id
      user_id_list = []
      @campaign.lists.each do |list|
        list.user_lists.each{ |customer| user_id_list.push({ user_id: customer.user.id }) }
      end
    end

    def send_channel_campaign
      channel_class = channel_mapper[@campaign.channel].constantize
      channel_class.new(@campaign).send_campaign
    end

    private

    def channel_mapper
      {
        'email' => 'EmailCampaign', 'mms' => 'MobileCampaign', 'sms' => 'MobileCampaign',
        'facebook_messenger' => 'MessengerCampaign'
      }
    end

    def send_fb_message_reminder
      page_access_token = get_page_access_token
      @campaign.lists.each do |list|
        list.get_users.each do |customer|
          user_fb_cred = customer[:user].fb_cred
          user_fb_cred_id = user_fb_cred.page_specific_id if user_fb_cred.present?
          fb_message_sender(page_access_token, user_fb_cred_id)
        end
      end if @campaign.lists.present?
    end

    def update_campaign
      @campaign.send_count = @campaign.send_count + 1
      @campaign.lists.each { |list| @campaign.campaign_user_lists.build(get_user_id) }
      @campaign.save(validate: false)
      @campaign.update_attribute('status', 3) if is_recurring_campaign_completed? || @campaign.one_time?
    end

    def is_recurring_campaign_completed?
      @campaign.repeat_days == @campaign.send_count if @campaign.recurring?
    end

    private

    def fb_message_sender(token, fb_id)
      email_service = SendEmail::EmailCampaign.new(campaign)
      if token.present? && fb_id.present?
        @facebook_messenger.send_text_message(token, fb_id, @campaign.text)
        send_fb_images(token, fb_id) if @campaign.images.present?
      else
        email_service.send_campaign if !(@campaign.is_a?(Reminder))
      end
    end

    def send_fb_images(page_token, fb_cred_id)
      @campaign.images.each do |image|
        @facebook_messenger.send_attachment(page_token, fb_cred_id, 'image', image.avatar.url)
      end
    end

    def get_subscribed_pages
      @campaign.user.fb_pages.subscribed # get merchant fb pages which are subscribed
    end

    def get_page_access_token
      subscribed_pages = get_subscribed_pages
      subscribed_pages[0].page_access_token if subscribed_pages.present?
    end
  end
end
