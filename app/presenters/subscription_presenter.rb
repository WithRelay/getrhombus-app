class SubscriptionPresenter < BasePresenter

  def get_amount
    str = "#{Toolbox::Decimal.to_int_or_2dp(@model.plan_amount.to_f/100)}"
    str += " (#{@model.quantity})" if @model.quantity > 1
    str
  end

end
