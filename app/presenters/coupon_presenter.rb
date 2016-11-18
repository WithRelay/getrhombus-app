class CouponPresenter < BasePresenter

  def zone_timestamp
    @model.redeem_by.present? ? Time.zone.at(@model.redeem_by).strftime("%d/%m/%Y %I:%M %p") : ''
  end

  def format_amount
    "%.2f" %(@model.amount_off.to_f/100)  if @model.amount_off.present?
  end

  def get_selected_coupon_type
    (@model.new_record? || @model.amount_off.present?) ? "amount_off" : "percent_off"
  end

end