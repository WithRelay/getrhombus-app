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
        list.get_user.each{ |customer| user_id_list.push({ user_id: customer[:user].id }) }
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

    def update_campaign
      @campaign.send_count = @campaign.send_count + 1
      @campaign.lists.each { |list| @campaign.campaign_user_lists.build(get_user_id) }
      @campaign.save(validate: false)
      @campaign.update_attribute('status', 3) if is_recurring_campaign_completed? || @campaign.one_time?
    end

    def is_recurring_campaign_completed?
      @campaign.repeat_days == @campaign.send_count if @campaign.recurring?
    end
  end
end
