class Api::V1::CouponsController < API::V1::BaseController

  def check_coupon_name
    res = current_user.coupons.where("lower(name) = ?", params[:coupon][:name].downcase)
    if res.empty?
      render json: { valid: true }.to_json
    else
      render json: { valid: false }.to_json
    end
  end

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

end
