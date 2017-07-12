class Api::V1::NumbersController < API::V1::BaseController

  def search
    if current_user && current_user.user_level == 1
      res = TextingService.search_number(params)
      render json: res, status: res[:error] ? 500 : 200
    else
      render json: { error: "Forbidden. That simple." }, status: 403
    end
  end

  def hosted_number_order
    if current_user && current_user.user_level == 1
      response = HostedSmsService.init_hosted_sms(current_user, params, events_twilio_url)
      render json: { res: response }, status: 200
    else
      render json: { error: "Forbidden. That simple." }, status: 403
    end
  end

end