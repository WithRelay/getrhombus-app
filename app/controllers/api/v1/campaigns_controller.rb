class Api::V1::CampaignsController < API::V1::BaseController

  def image_delete
    image_ref = find_image_ref(imageable_type: 'Campaign', image_id: params[:image_id])
    image_ref.delete if image_ref
    render json: { response: 'Deleted' }, status: 200
  end


  def delete_campaign
    campaign = current_user.campaigns.find_by_id(params[:id])
    if campaign.present?
      campaign.campaign_user_lists.delete_all
      campaign.campaign_lists.delete_all
      campaign.delete
      campaign.destroy_campaign_jobs
      flash = { status: 200, notice: 'Campaign is being succesfully deleted' }
    else
      flash = { status: 404, error: 'Sorry campaign could not delete please try again' }
    end
    render json: flash
  end

  def change_status
    campaign = current_user.campaigns.find_by_id(params[:id])
    if campaign.present?
      status = campaign.active? ? 2 : 1
      campaign.update_attribute('status', status)
      campaign.change_job_status
    end
    render json: { status: 200, notice: "Campaign status change" }
  end

  def send_test_email
    campaign = current_user.campaigns.build(campaign_params, image_params)
    if campaign.save(validate: false)
      flash_msg = { notice: 'Email Send' }
      # we can send object to active jobs but it is good not to send complex object to active jobs
      # http://chriskottom.com/blog/2015/11/bulletproof-rails-background-jobs/
      SendNowCampaignJob.perform_now(campaign.id)
    else
      flash_msg = { error: campaign.errors.full_messages }
    end
    campaign.destroy
    render json: { status: 200 }.merge(flash_msg)
  end

  # Check uniqueness of campaign name from remote post request from campaign_form_validator.js
  def check_campaign_name
    render json: { valid: find_campaign_by_name.blank? }
  end

  # uplaoding image from local and url
  def upload_images
    image = params[:img_url].present? ? open(params[:img_url]) : params[:image]
    render json:  validation_messages(image)
  end

  def find_campaign_by_name
    # campaign name is unique but only with particular user
    campaign = current_user.campaigns.check_campaign_uniqueness(params[:campaign][:name])
    if params[:id].present?
      params[:id].to_i == campaign[0].id ? [] : campaign
    else
      campaign
    end
  end

  def campaign_params
    # enums are define as integer but params are in string and rails is not converting string to integer
    params.require(:campaign).permit(:list_name, :channel, :repeat_days, :date_time, :deliver_now,
                                     :frequency_type, :text, :subject).tap do |c|
                                        c[:channel] = c[:channel].to_i
                                        c[:frequency_type] = c[:frequency_type].to_i
                                        c[:deliver_now] = c[:deliver_now] == '1' ? true : false
                                        c[:subject] = nil unless c[:channel] == 3
                                        c[:date_time] = Time.current + 1.hour
                                      end.merge({ status: 4 })
  end

  def image_params
    params.require(:campaign).permit(:avatar, image_id:[])
  end
end
