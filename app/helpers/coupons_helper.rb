module CouponsHelper

  def get_selected_coupon_type(coupon)
    coupon.new_record? || coupon.amount_off.present? ? "amount_off" : "percent_off"
  end

  def zone_timestamp(timestamp)
    # Format the string output with #strftime method => "March 23, 2013 at 09:48 AM"
    Time.at(timestamp).in_time_zone(current_user.time_zone).strftime("%B %e, %Y at %I:%M %p")
  end
end
