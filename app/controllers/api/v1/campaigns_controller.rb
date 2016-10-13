class Api::V1::CampaignsController < API::V1::BaseController
 
  def image_delete
    image_ref = find_image(imageable_type: 'Message', image_id: params[:id])
    image_ref.delete if image_ref
    render json: { response: "Deleted" }, status: 200
	end

  def upload_images
    if valid_uploaded_images(params[:image])
      render json: { status: 200, message: 'success' }
    else
      render json: { status: 401, message: 'sorry file type/size is not supported' }
    end
  end

end
