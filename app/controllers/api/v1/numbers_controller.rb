class Api::V1::NumbersController < Api::V1::BaseController

  def search
    if current_user.try(:is_merchant?)
      res = TextingService.search_number(params)
      render json: res, status: res[:error] ? 500 : 200
    else
      render json: { error: "Forbidden. That simple." }, status: 403
    end
  end

  def hosted_number_order
    if current_user.try(:is_merchant?)
      response = HostedSmsService.init_hosted_sms(current_user, params, events_twilio_url)
      render json: { res: response }, status: 200
    else
      render json: { error: "Forbidden. That simple." }, status: 403
    end
  end

end