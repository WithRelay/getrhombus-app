class Api::V1::CampaignsController < API::V1::BaseController
  def image_delete
    image_ref = find_image(imageable_type: 'Message', image_id: params[:id])
    image_ref.delete if image_ref
    render json: { response: "Deleted" }, status: 200
	end
end
