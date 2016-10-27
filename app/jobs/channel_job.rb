class ChannelJob
  @queue = :default

  def self.perform(campaign_id)
    campaign = Campaign.find_by_id(campaign_id)
    channel_class = channel_hash[campaign.channel].constantize
    campaign.channel == 'email' ? channel_class.new(campaign).send_campaign : channel_class.send_campaign(campaign)
  end

  private_class_method

  def self.channel_hash
    {
      'sms'=>'SmsService', 'mms'=>'MmsService',
      'facebook_messenger'=>'FacebookMessengerService',
      'email'=>'EmailService'
    }
  end
end
