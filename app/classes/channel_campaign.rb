# Class responsible for sending campaigns to a group of users by channel emails, mms/sms, facebook messenger
module ChannelCampaign
  class SendCampaign

    def initialize(campaign)
      @campaign = campaign
    end

    def send_channel_campaign
      channel_class = channel_string_class.constantize
      @recipients = get_recipients
      
      if @recipients.present?
        @results = channel_class.new(@campaign, @recipients).send_campaign
        @recipients = @results[:recipients]
        update_campaign(@campaign.channel) unless @campaign.test? || @recipients.blank?   # should come before retrying
        email_fallback if retry_campaign?
      end
    end

    private

    # test emails, contacts based list & email shouldn't retry....
    def retry_campaign?
      !@campaign.test? && @results[:retry_list].present? && @campaign.lists.first.customer? && @campaign.channel != 'email'
    end

    def channel_string_class
      channel_mapper[@campaign.channel]
    end

    def get_recipients
      return [{ email: @campaign.user.email }] if @campaign.test?
      @campaign.lists.first.get_mcs             # relationally campaigns can have more lists...but not in practice
    end

    def email_fallback
      @results = EmailCampaign.new(@campaign, @results[:retry_list]).send_campaign 
      should_update_campaign = @recipients.blank? && @results[:recipients].present?
      @recipients = @results[:recipients]
      update_campaign('email', should_update_campaign)
    end

    # The key in channel mapper is enum channels of campaign.
    # Refer to campaign model. Values are strings which are the class names
    def channel_mapper
      { 'email' => 'EmailCampaign', 'mms' => 'MobileCampaign', 'sms' => 'MobileCampaign', 'facebook_messenger' => 'MobileCampaign' }
    end

    # updates campaign details after sending campaign success.
    def update_campaign(channel, update_campaign = true)
      # sent count is needed in campaigns so it can be used to update campaign recipients
      if update_campaign
        @campaign.increment(:sent_count) 
        @campaign.status = 3 if @campaign.one_time?
        @campaign.next_send_at += @campaign.repeat_days.days if @campaign.recurring?
        @campaign.save(validate: false)
      end

      # relationally campaigns can have more lists...but not in practice
      list_id = @campaign.lists.first.id
      @recipients.each do |r|
        CampaignRecipient.find_or_create_by({ campaign_id: @campaign.id, sent_count: @campaign.sent_count, list_id: list_id,
                                                  customer_contact_type: r.class.to_s, customer_contact_id: r.id, channel: channel }) 
      end
    end

  end
end
