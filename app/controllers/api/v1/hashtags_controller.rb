class Api::V1::HashtagsController < API::V1::BaseController

  def index
    begin
      if params[:query]
        q = params[:query].downcase
        res = current_user.hashtags.where("lower(description) like ? or lower(tag) like ?", "%#{q}%", "%#{q}%")
      else
        res = current_user.hashtags
      end

      render json: { "hashtags" => res }, status: 200
    rescue StandardError => e
      render json: { error: "Unable to find your hashtags" }, status: 500
    end
  end

  def create
    if Hashtag.create(name: params[:name] , tag: params[:tag])
      render json: output
    else
      render json: { "error": "unable to create hashtag" }, status: 500
    end
  end

  def image_delete
    image_ref = find_image(imageable_type: 'Hashtag', imageable_id: params[:id], image_id: params[:img_id])
    image_ref.delete if image_ref
    render json: { response: "Deleted" }, status: 200
  end
end
