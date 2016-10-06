class Api::V1::CampaignsController < API::V1::BaseController
  def image_delete
    image_ref = find_image(imageable_type: 'Message', image_id: params[:id])
    image_ref.delete if image_ref
    render json: { response: "Deleted" }, status: 200
	end

  def upload_images
    if valid_uploaded_images(params[:image])
      image = Image.new(avatar: params[:image])
      if image.save
        render json: { type: image.avatar_content_type.split('/').first,
                       name: image.avatar_file_name, id: image.id }
      else
        render json: { status: 401, message: 'sorry file could not upload' }
      end
    else
      render json: { status: 401, message: 'sorry file type/size is not supported' }
    end
  end
end
