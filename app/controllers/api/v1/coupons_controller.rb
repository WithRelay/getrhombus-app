class Api::V1::CouponsController < Api::V1::BaseController

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

   # create coupons from modal
  def create
    begin
      status = 500
      @coupon = Coupon.new(coupon_params)
      if @coupon.create_coupon({ team: current_user })
        response = 'Coupon was created'
        status = 200
      else
        response = @coupon.errors.messages.present? ? @coupon.errors.full_messages : "We couldn't create the coupon"
        @plan.destroy     # revoke created plan on error
      end
    rescue StandardError => e
      response = 'Something went wrong on our end.'
    end
    render json: { response: response }, status: status
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

  private

    def coupon_params
      params.require(:coupon).permit(:name, :amount_off, :duration, :duration_in_months, :max_redemptions,
        :percent_off, :redeem_by).tap{ |coupon|
        # amount_off should be in cent
        # round to take care of inaccurate floating point math. see 100 * 1.1
        coupon[:amount_off] = (100 * coupon[:amount_off].to_f).round if coupon[:amount_off].present?
        coupon[:redeem_by] = Time.zone.parse(coupon[:redeem_by]).to_i if coupon[:redeem_by].present?
      }
    end
end
