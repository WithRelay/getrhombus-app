class Api::V1::CouponsController < API::V1::BaseController

  def check_coupon_name
    res = current_user.coupons.where("lower(name) = ?", params[:coupon][:name].downcase)
    if res.empty?
      render json: { valid: true }.to_json
    else
      render json: { valid: false }.to_json
    end
    # need to still render json response if res isn't empty
  end
end
