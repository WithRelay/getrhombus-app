class ChannelJob
  @queue = :campaign

  def self.perform(campaign_id)
    campaign = Campaign.includes([:images, lists:[:user_lists]]).where(id: campaign_id)[0]
    channel_class = channel_hash[campaign.channel].constantize
    campaign.email? ? channel_class.new(campaign).send_campaign : channel_class.send_campaign(campaign)
  end

  private_class_method

  def self.channel_hash
    {
      'sms'=>'SmsService', 'mms'=>'MmsService',
      'facebook_messenger'=>'FacebookMessengerService',
      'email'=>'SendEmail::EmailCampaign'
    }
  end
end
