module CouponsHelper

  def get_selected_coupon_type(coupon)
    coupon.new_record? || coupon.amount_off.present? ? "amount_off" : "percent_off"
  end
end
