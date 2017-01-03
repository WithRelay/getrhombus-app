class Api::V1::CampaignsController < API::V1::BaseController

  def image_delete
    image_ref = find_image_ref(imageable_type: 'Campaign', image_id: params[:image_id])
    image_ref.delete if image_ref
    render json: { response: "Deleted" }, status: 200
  end

  def send_test_email
    job_params = { user_id: current_user.id, campaign_params: campaign_params, image_params: image_params }
    # we can send object to active jobs but it is good not to send complex object to active jobs
    # http://chriskottom.com/blog/2015/11/bulletproof-rails-background-jobs/
    send_email = SendNowCampaignJob.perform_now(job_params)
    render json: { status: 200, notice: 'Email Send' }
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
    current_user.campaigns.check_campaign_uniqueness(params[:campaign][:name])
  end

  def campaign_params
    # enums are define as integer but params are in string and rails is not converting string to integer
    params.require(:campaign).permit(:name, :list_name, :channel, :repeat_days, :date_time, :deliver_now,
                         :frequency_type, :text, :subject).tap do |c|
                          c[:channel] = c[:channel].to_i
                          c[:frequency_type] = c[:frequency_type].to_i
                          c[:deliver_now] = c[:deliver_now] == '1' ? true : false
                          c[:subject] = nil unless c[:channel] == 3
                          c[:date_time] = c[:date_time].present? ? c[:date_time].in_time_zone(current_user.time_zone) : nil
                        end.merge({ status: 4 })
  end

  def image_params
    params.require(:campaign).permit(avatar:[], image_id:[])
  end
end
