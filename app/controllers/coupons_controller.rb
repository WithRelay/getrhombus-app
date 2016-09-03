class CouponsController < ApplicationController
  before_action :set_coupon, only: [:show, :edit, :update, :destroy]

  respond_to :html

  def index
    @coupons = Coupon.all
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
    @coupon.save
    respond_with(@coupon)
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
      params[:coupon]
    end
end
