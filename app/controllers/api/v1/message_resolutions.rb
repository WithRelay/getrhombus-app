class Api::V1::MessageResolutionsController < API::V1::BaseController

  def index
    begin
      render json: current_user.message_resolutions
    rescue StandardError => e
      render json: [], status: 500
    end
  end

end