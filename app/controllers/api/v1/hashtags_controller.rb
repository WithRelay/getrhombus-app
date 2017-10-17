class Api::V1::HashtagsController < Api::V1::BaseController

  def index
    begin
      if params.key?(:query)
        q = params[:query].downcase
        res = current_user.hashtags.where("(lower(name) like ? or lower(tag) like ?) and tag_type = 1", "%#{q}%", "%#{q.gsub(/\s+/, '')}%")
      else
        res = current_user.hashtags
      end

      render json: { "hashtags" => res }, status: 200
    rescue StandardError => e
      render json: { error: "Unable to find your hashtags" }, status: 500
    end
  end

  # Check uniqueness of campaign name from remote post request from campaign_form_validator.js
  def check_hashtag_name
    render json: { valid: !current_user.hashtags.where("lower(name) = ?", params[:hashtag][:name].downcase).exists? }
  end

  def image_delete
    image_ref = find_image_ref(imageable_type: 'Hashtag', image_id: params[:image_id])
    image_ref.delete if image_ref
    render json: { response: "Deleted" }, status: 200
  end
end
