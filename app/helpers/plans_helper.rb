module PlansHelper
  def subscribed_customer_count(plan)
    Subscription.where(plan_id: plan.id).count
  end
end
