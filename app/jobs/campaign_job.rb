# sends email to campaign user list as scheduled
class CampaignJob < ActiveJob::Base
  queue_as :default

  def perform(campaign)
    channel_class = "#{campaign.channel.split(" ").join()}Service".constantize
    channel_class.send_campaign(campaign)
  end
end
