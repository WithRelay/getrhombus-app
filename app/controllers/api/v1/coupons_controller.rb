class Api::V1::CouponsController < API::V1::BaseController

  def check_coupon_name
    res = current_user.coupons.where("lower(name) = ?", params[:coupon][:name].downcase)
    render json: { valid: res.empty? }
  end

  def index
    begin
      if params[:name]
        res = valid_coupon(current_user.coupons.where("lower(name) like ?", "%#{params[:name].downcase}%"))
      else
        res = valid_coupon(current_user.coupons)
      end
      render json: { "coupons" => res }, status: 200
    rescue StandardError => e
      render json: { error: "Unable to find your Coupons" }, status: 500
    end
  end

  def valid_coupon(coupons)
    array_of_coupons = []
    coupons.each do |c|
      array_of_coupons << c if c.is_valid?
    end
    array_of_coupons
  end

end
