class SubscriptionPresenter < BasePresenter

  def get_amount
    "#{Toolbox::Decimal.to_int_or_2dp(@model.plan_amount.to_f/100)}"
  end

end
