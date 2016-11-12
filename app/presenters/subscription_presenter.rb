class SubscriptionPresenter < BasePresenter
  def get_plan_info
    plan = Plan.find @model.plan_id
    amount = "%.2f" %(plan.amount.to_f/100)
    interval_count = plan.interval_count
    interval = (interval_count > 1)? (plan.interval.pluralize): plan.interval
    "#{plan.name}(#{plan.currency} #{amount} every #{interval_count} #{interval})"
  end
end
