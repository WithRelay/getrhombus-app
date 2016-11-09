class Api::V1::SubscriptionsController < API::V1::BaseController

  def get_coupon
    begin
      if params[:name]
        res = current_user.coupons.where("lower(name) like ?", "%#{params[:name].downcase}%")
      else
        res = current_user.coupons
      end
      render json: { "coupons" => res }, status: 200
    rescue StandardError => e
      render json: { error: "Unable to find your Coupons" }, status: 500
    end
  end

  def get_plan
    begin
      if params[:name]
        res = current_user.plans.where("lower(name) like ?", "%#{params[:name].downcase}%")
      else
        res = current_user.plans
      end
      render json: { "plans" => res }, status: 200
    rescue StandardError => e
      render json: { error: "Unable to find your Plans" }, status: 500
    end
  end

end
