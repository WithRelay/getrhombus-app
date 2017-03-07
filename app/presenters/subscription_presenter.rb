class SubscriptionPresenter < BasePresenter

  def get_amount
    "%.2f" %(@model.plan.amount.to_f/100)
  end

end
