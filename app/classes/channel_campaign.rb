# Class responsible for sending camapaigns to a group of users by channel emails, mms/sms, facebook messenger
module ChannelCampaign
  class SendCampaign

    def initialize(campaign)
      @campaign = campaign # campaign object
    end

    def send_channel_campaign
      # channel mappers maps campaign channel to its respective class
      # declare constant with a string eg: string EmailCampaign will act like contant EmailCampaign
      channel_class = channel_mapper[@campaign.channel].constantize
      # all channels classes like messenger_campaign, mobile_campaign, email_campaign
      # and has a common method send campaign which send campaign to a group of users
      send_campaign = channel_class.new(@campaign).send_campaign
      update_test_campaign if @campaign.test?
      retry_other_channel(channel_class, send_campaign) unless retry_campaign?
    end

    private

    def retry_campaign?
      @campaign.test? && @campaign.lists[0].try(:channel).present?
    end

    def retry_other_channel(campaign_channel, failure_user_list)
      unless campaign_channel == EmailCampaign && !failure_user_list.present?
        unless MobileCampaign.new(@campaign, failure_user_list).send_failure
          update_campaign if EmailCampaign.new(@campaign, failure_user_list).send_failure
        else
          update_campaign
        end
      else
        update_campaign
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

    # The key in channel mapper is enum channels of campaign please refer to campaign model
    # Value of the key is string which is same as class name
    def channel_mapper
      {
        'email' => 'EmailCampaign', 'mms' => 'MobileCampaign', 'sms' => 'MobileCampaign',
        'facebook_messenger' => 'MessengerCampaign'
      }
    end

    def update_test_campaign
      @campaign.images.delete_all
      @campaign.campaign_lists.delete_all
      @campaign.destroy
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
