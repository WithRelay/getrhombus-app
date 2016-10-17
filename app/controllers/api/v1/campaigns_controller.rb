class Api::V1::CampaignsController < API::V1::BaseController

  def image_delete
    image_ref = find_image(imageable_type: 'Message', image_id: params[:id])
    image_ref.delete if image_ref
    render json: { response: "Deleted" }, status: 200
	end

  def upload_images
    render json:  validation_messages(params[:image])
  end

  def upload_from_url
    image = open(params[:img_url])
    encoded_image = Base64.encode64(open(params[:img_url]) { |io| io.read })
    render json: validation_messages(image).merge(encoded_image: encoded_image)
  end
end
