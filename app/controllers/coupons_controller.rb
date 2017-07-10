class CouponsController < ApplicationController

  include DashboardNotification

  before_action :set_coupon, only: [:destroy]
  before_action :set_notifications, only: [:index, :manage_coupons]

  respond_to :html, :js

  def index
    # get subscription id to use to determine if destroy link should show up
    @coupon = Coupon.new
    @coupons = coupons

    @coupons.present? ? render_requested_format(@coupons) : render(:empty_coupon)
  end

  def destroy
    unless Subscription.exists?(coupon_id: @coupon.id)
      if @coupon.delete_coupon
        @coupon.destroy
        flash[:notice] = 'Coupon was deleted'
      else
        flash[:error] = "We couldn't delete the coupon"
      end
    else
      flash[:warning] = "You can't delete a used Coupon..."
    end
    redirect_to user_manage_coupons_path(current_user)
  end

  def manage_coupons
    @manage_coupons = coupons
    if @manage_coupons.present?
      respond_to do |format|
        format.js { render partial: 'coupon_manage.js.erb', locals: { obj: @manage_coupons } }
        format.html
      end
    else
      render 'empty_manage_coupon'
    end
  end

  private
    def coupons
      current_user.coupons
        .joins("LEFT JOIN subscriptions s ON s.coupon_id = coupons.id")
        .select('coupons.id, name, amount_off, percent_off, currency, duration, duration_in_months, max_redemptions,
                  percent_off, redeem_by, coupons.created_at, s.id as subscription_id')
        .paginate(page: params[:page], per_page: PAGINATION_PER_PAGE)
        .order('coupons.created_at DESC')
    end

    def set_coupon
      @coupon = Coupon.find(params[:id])
    end

end
