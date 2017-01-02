# sends email to campaign user list as scheduled
class SendNowCampaignJob < ActiveJob::Base
  queue_as :send_now_campaign

  def perform(job_params)
    unless job_params[:campaign_id].present?
      current_user = User.find_by_id(job_params[:user_id])
      campaign = current_user.campaigns.build(job_params[:campaign_params], job_params[:image_params])
    else
      campaign = Campaign.find_by_id(job_params[:campaign_id])
    end
    ChannelCampaign::SendCampaign.new(campaign).send_channel_campaign
  end
end
