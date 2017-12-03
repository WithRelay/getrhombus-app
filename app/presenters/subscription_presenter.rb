# Subscription Presenter
class SubscriptionPresenter < BasePresenter
  def get_amount
    str = Toolbox::Decimal.to_int_or_2dp(@model.plan_amount.to_f / 100).to_s
    str += " (#{@model.quantity})" if @model.quantity > 1
    str
  end

  def next_billing
    next_billing_time = @model.current_period_end
    time_zone = @model.merchant.time_zone
    Time.at(next_billing_time).in_time_zone(time_zone).strftime('%B %e, %Y')
  end
end
