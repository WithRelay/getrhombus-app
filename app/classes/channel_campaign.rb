# Class responsible for sending camapaigns to a group of users by channel emails, mms/sms, facebook messenger
module ChannelCampaign
  class SendCampaign

    def initialize(campaign)
      @campaign = campaign # campaign object
      @failure_user_list = []
    end

    def send_channel_campaign
      # declare constant with a string eg: string EmailCampaign will act like contant EmailCampaign
      # all channels classes like messenger_campaign, mobile_campaign, email_campaign
      # and has a common method send campaign which send campaign to a group of users
      channel_class = channel_string_class.constantize
      @failure_user_list = channel_class.new(@campaign).send_campaign
      unless @campaign.reminder_campaign?
        retry_other_channel unless retry_campaign?
      end
      update_campaign
    end

    private

    def retry_campaign?
      @campaign.test? || @campaign.lists[0].try(:channel).nil?
    end

    def channel_string_class
      # channel mappers maps campaign channel to its respective class
      return channel_mapper[@campaign.channel]
    end

    def retry_other_channel
      # valid_retry_channel contains ["MobileCampaign", "MobileCampaign", "MessengerCampaign"]
      valid_retry_channel = channel_mapper.values[1..3]
      # valid_retry_channel[2] contains "MessengerCampaign"
      if @failure_user_list.present? && valid_retry_channel.include?(channel_string_class)
        if valid_retry_channel[2].include?(channel_string_class)
          retry_email_campaign unless retry_mobile_campaign
        elsif valid_retry_channel[0].include?(channel_string_class)
          retry_email_campaign
        end
      end
    end

    # returns array of user_id list hash eg: [{ user_id: 1 }, { user_id: 2 }]
    def get_user_id
      user_id_list = []
      @campaign.lists.each do |list|
        list.get_users.each{ |customer| user_id_list.push({ user_id: customer[:user].id }) }
      end
      user_id_list
    end

    def retry_email_campaign
      EmailCampaign.new(@campaign, @failure_user_list).send_failure ? update_campaign : false
    end

    def retry_mobile_campaign
      MobileCampaign.new(@campaign, @failure_user_list).send_failure ? update_campaign : false
    end

    # The key in channel mapper is enum channels of campaign please refer to campaign model
    # Value of the key is string which is same as class name
    def channel_mapper
      {
        'email' => 'EmailCampaign', 'mms' => 'MobileCampaign', 'sms' => 'MobileCampaign',
        'facebook_messenger' => 'MessengerCampaign'
      }
    end

    # updates campaign details after sending campaign success.
    def update_campaign
      @campaign.send_count = @campaign.send_count + 1
      @campaign.lists.each { |list| @campaign.campaign_user_lists.build(get_user_id) }
      @campaign.save(validate: false)
      @campaign.update_attribute('status', 3) if is_recurring_campaign_completed? || @campaign.one_time?
    end

    # Check if recurring campaign is completed or not by comparing repeat days and send count.
    def is_recurring_campaign_completed?
      @campaign.repeat_days == @campaign.send_count if @campaign.recurring?
    end
  end
end
