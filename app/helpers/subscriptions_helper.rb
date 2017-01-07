module SubscriptionsHelper
  def saas_sub(subsriptions)
    subsriptions.where(status: 'active').last.id
  end

  def amount(subsriptions)
    saas_subs = subsriptions.where(status: 'active').last
    plan = Plan.find saas_subs.plan_id
    per_month_amount(plan)
  end

  def per_month_amount(plan)
    amount = plan.amount
    interval = plan.interval
    if interval == 'week'
      (amount*7*plan.interval_count)/(30 * 100)
    elsif interval == 'month'
      amount/100
    else
      (amount*12*plan.interval_count)/100
    end
  end
end
