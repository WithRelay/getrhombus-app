# sends email to campaign user list as scheduled
class CampaignJob < ActiveJob::Base
  queue_as :default

  def perform(campaign)
    channel_class = channel_hash[campaign.channel].constantize
    channel_class.send_campaign(campaign)
  end

  def channel_hash
    # this hash is because no need to use lots of conditional statement, if you have a
    # differenct class associate with channel please provide the appropriate class name
    {
      'sms'=>'SmsService', 'mms'=>'MmsService',
      'facebook_messenger'=>'FacebookMessengerService',
      'email'=>'EmailService'
    }
  end
end
