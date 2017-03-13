class SubscriptionPresenter < BasePresenter

  def get_amount
    "#{Toolbox::Decimal.to_2dp(@model.plan.amount.to_f/100)}"
  end

end
