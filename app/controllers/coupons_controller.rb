class CouponsController < ApplicationController
  before_action :set_coupon, only: [:show, :destroy]

  respond_to :html

  def index
    @coupons = current_user.coupons.paginate(:page => params[:page], :per_page => 25).order('updated_at DESC')
    #@coupons = Coupon.all
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
    res =  @coupon.create_coupon({ team: current_user })

    if res
      @coupon.user_id = current_user.id
      @coupon.save
      @coupon.update(stripe_coupon_id: res[0].id, stripe_livemode: res[0].livemode)
      redirect_to user_coupons_path, flash: { notice: 'Coupon was created'}
    elsif res[0] == false
      redirect_to new_user_coupon_path, flash: { error: 'We couldn\'t create the coupon' }
    else
      redirect_to new_user_coupon_path, flash: { error: 'Something went wrong'}
    end
  end

  def destroy
    res = PaymentService.delete_coupon( @coupon.stripe_coupon_id)
    if res[0]
      @coupon.destroy
      redirect_to user_coupons_path, flash: { notice: 'Coupon was deleted'}
    elsif res[0] == false
      redirect_to user_coupons_path, flash: { error: 'We couldn\'t delete the coupon' }
    else
      redirect_to user_coupons_path, flash: { error: 'Something went wrong'}
    end
  end

  private
    def set_coupon
      @coupon = Coupon.find(params[:id])
    end

    def coupon_params
      params.require(:coupon).permit(:name, :amount_off, :duration, :duration_in_months, :max_redemptions,
        :percent_off, :redeem_by, :coupon_type).tap{ |coupon|
        if coupon['redeem_by'].present?
          datetime =  DateTime.parse(coupon['redeem_by'])
          coupon['redeem_by'] =  datetime.to_time.to_i
        end
        coupon['currency'] = current_user.currency
      }
    end

end
