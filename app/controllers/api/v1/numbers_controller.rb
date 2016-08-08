class Api::V1::NumbersController < API::V1::BaseController

  def search
    if current_user && current_user.user_level == 1
      res = TextingService.search_number(params)
      render json: res, status: res[:error] ? 500 : 200
    else
      render json: { error: "Forbidden. That simple." }, status: 403
    end
  end

end