class CouponsController < ApplicationController
  before_action :set_coupon, only: [:show, :destroy]

  respond_to :html

  def index
    # get subscription id to use to determine if destroy link should show up
    @coupons = current_user.coupons
              .joins("LEFT JOIN subscriptions s ON s.coupon_id = coupons.id")
              .select('coupons.id, name, amount_off, percent_off, currency, duration, duration_in_months, max_redemptions,
                        percent_off, redeem_by, s.id as subscription_id')
              .paginate(page: params[:page], per_page: 25)
              .order('coupons.created_at DESC')

    respond_with(@coupons)
  end

  def show
    respond_with(@coupon)
  end

  def new
    @coupon = current_user.coupons.build
    respond_with(@coupon)
  end

  def create
    @coupon = Coupon.new(coupon_params)

    if @coupon.create_coupon({ team: current_user })
      redirect_to user_coupons_path, flash: { notice: 'Coupon was created' }
    else
      # revoke amount_off from cent
      @coupon.amount_off = @coupon.amount_off/100.to_f if @coupon.amount_off
      @coupon.destroy     # revoke created coupon on error
      if @coupon.errors.messages.present?
        error = @coupon.errors.full_messages
        flash[:error] = error
      else
        flash[:error] = "We couldn't create the coupon"
      end
      render :new
    end
  end

  def destroy
    unless Subscription.exists?(coupon_id: @coupon.id)
      if @coupon.delete_coupon
        @coupon.destroy
        redirect_to user_coupons_path, flash: { notice: 'Coupon was deleted' }
      else
        redirect_to user_coupons_path, flash: { error: "We couldn't delete the coupon" }
      end
    else
      redirect_to user_coupons_path, flash: { warning: "You can't delete a used Coupon..." }
    end
  end

  private
    def set_coupon
      @coupon = Coupon.find(params[:id])
    end

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
