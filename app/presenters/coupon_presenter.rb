class CouponPresenter < BasePresenter

  def zone_timestamp
    @model.redeem_by.present? ? Time.zone.at(@model.redeem_by).strftime("%b. %d, %Y") : ''
  end

  def format_amount
    @model.amount_off.present? ? "$%.2f" %(@model.amount_off.to_f/100) : "#{@model.percent_off}%"

  end

  def get_selected_coupon_type
    (@model.new_record? || @model.amount_off.present?) ? "amount_off" : "percent_off"
  end

  def coupon_type
    if (@model.new_record? || @model.amount_off.present?)
      '<div class="fixed-amount-coupon shrink-text table-text"><strong>Fixed amount</strong></div>'.html_safe
    else
      '<div class="percentage-coupon shrink-text table-text"><strong>Percentage</strong></div>'.html_safe
    end
  end
end