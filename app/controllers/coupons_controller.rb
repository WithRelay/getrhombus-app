class CouponsController < ApplicationController
  before_action :set_coupon, only: [:show, :edit, :update, :destroy]

  respond_to :html

  def index
    @coupons = Coupon.all
    @referrer = Referrer.new
    respond_with(@coupons)
  end

  def show
    respond_with(@coupon)
  end

  def new
    @coupon = Coupon.new
    respond_with(@coupon)
  end

  def edit
  end

  def create
    @coupon = Coupon.new(coupon_params)
    @coupon.user_id = current_user.id
    if @coupon.create_coupon({ team: current_user })  #@coupon.save
      redirect_to user_coupons_path       #respond_with(@coupon)
    else
      respond_with(@subscription)
    end
  end

  def update
    @coupon.update(coupon_params)
    respond_with(@coupon)
  end

  def destroy
    @coupon.destroy
    respond_with(@coupon)
  end

  private
    def set_coupon
      @coupon = Coupon.find(params[:id])
    end

    def coupon_params
      params.require(:coupon).permit(:name, :amount_off, :duration, :duration_in_months, :max_redemptions,
            :percent_off, :redeem_by)
    end
end
