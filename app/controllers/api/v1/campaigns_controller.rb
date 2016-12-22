class Api::V1::CampaignsController < API::V1::BaseController

  def image_delete
    image_ref = find_image_ref(imageable_type: 'Campaign', image_id: params[:image_id])
    image_ref.delete if image_ref
    render json: { response: "Deleted" }, status: 200
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
end
