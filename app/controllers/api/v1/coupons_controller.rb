class Api::V1::CouponsController < API::V1::BaseController

  def check_coupon_name
    res = current_user.coupons.where("lower(name) = ?", params[:coupon][:name].downcase)
    render json: { valid: res.blank? }
  end

  def index
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

  def valid_coupon(coupons)
    array_of_coupons = []
    coupons.each do |c|
      array_of_coupons << c if c.is_valid?
    end
    array_of_coupons
  end

  def update
    @coupon = Coupon.find(params[:id])
    begin
      status = 500
      if @coupon.update_coupon(params[:coupon][:name], current_user)
        response = 'Coupon name updated successfully'
        status = 200
      else
        response = @coupon.errors.messages.present? ? @coupon.errors.full_messages : "We couldn't update the coupon name"
      end
    rescue StandardError => e
      response = 'Something went wrong on our end.'
    end
    render json: { response: response }, status: status
  end

end
