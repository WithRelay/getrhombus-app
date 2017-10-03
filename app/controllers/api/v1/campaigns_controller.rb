class Api::V1::CampaignsController < Api::V1::BaseController

  def image_delete
    image_ref = find_image_ref(imageable_type: 'Campaign', image_id: params[:image_id])
    image_ref.delete if image_ref
    render json: { notice: 'Deleted' }, status: 200
  end

  def delete_campaign
    campaign = current_user.campaigns.find_by_id(params[:id])
    if campaign.present?
      if campaign.campaign_recipients.exists?
        render json: { error: "You can only delete a campaign that hasn't run" }, status: 500
      else
        campaign.destroy_campaign_jobs
        campaign.destroy
        render json: { notice: 'Campaign has been deleted' }
      end
    else
      render json: { error: 'Campaign does not exist' }, status: 500
    end
  end

  def change_status
    campaign = current_user.campaigns.find_by_id(params[:id])
    if campaign.present?
      status = campaign.active? ? 2 : 1
      campaign.update_attribute('status', status)
      campaign.change_job_status
    end
    render json: { notice: "Campaign status has been changed" }, status: 200
  end

  # test emails ignore attachments from client js so image_params is needless
  def send_test_email
    begin
      status = 500
      campaign = current_user.campaigns.build(campaign_params, image_params)
      
      if campaign.save(validate: false)
        status = 200
        flash_msg = { notice: 'Test Email Sent' }
        # we can send object to active jobs but it is not good to send complex object to active jobs. 
        # http://chriskottom.com/blog/2015/11/bulletproof-rails-background-jobs/
        SendNowCampaignJob.set(queue: campaign.send_now_queue).perform_now(campaign.id)
      else
        flash_msg = { error: campaign.errors.full_messages }
      end
    rescue StandardError => e
      flash_msg = { error: 'Unable to send test email' }
    end
    
    campaign.destroy
    render json: flash_msg, status: status
  end

  # Check uniqueness of campaign name from remote post request from campaign_form_validator.js
  def check_campaign_name
    render json: { valid: find_campaign_by_name.blank? }
  end

  # uplaoding image from local and url
  def upload_images
    image = params[:img_url].present? ? open(params[:img_url]) : params[:image]
    render json: validation_messages(image)
  end

  def find_campaign_by_name
    # campaign name is unique but only with particular user
    campaign = current_user.campaigns.check_campaign_uniqueness(params[:campaign][:name])
    params[:id].present? && params[:id].to_i == campaign[0].id ? [] : campaign
  end

  def campaign_params
    # enums are define as integer but params are in string and rails is not converting string to integer
    params.require(:campaign).permit(:list_id, :channel, :repeat_days, :date_time, :deliver_now,
                                     :frequency_type, :text, :subject).tap do |c|
                                        c[:channel] = c[:channel].to_i
                                        c[:frequency_type] = c[:frequency_type].to_i
                                        c[:deliver_now] = c[:deliver_now] == '1' ? true : false

                                        c[:repeat_days] = nil if c[:frequency_type] == 0
                                        c[:date_time] = nil if c[:frequency_type] == 0 && c[:deliver_now]
                                        c[:subject] = nil unless c[:channel] == 3
                                        c[:date_time] = Time.current + 1.hour
                                        c[:status] = 4
                                      end
  end

  def image_params
    params.require(:campaign).permit(:avatar, image_id:[])
  end
end
