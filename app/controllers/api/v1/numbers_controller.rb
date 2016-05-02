class Api::V1::NumbersController < API::V1::BaseController

  def search
    if current_user && current_user.user_level == 1
      render json: { numbers: TextingService.search_number(params[:search_number], params[:type], current_user.country) } 
    else
      render json: { "error": "Something went wrong." }, status: 500
    end
  end

end