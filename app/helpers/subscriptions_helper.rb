module SubscriptionsHelper
  def get_saas_sub_id
    saas_sub.id if current_user.is_merchant? && saas_sub.present?
  end

  def get_saas_plan_amount
    (Plan.find saas_sub.plan_id).amount/100 if current_user.is_merchant? && saas_sub.present?
  end

  def saas_plan_name
    (Plan.find saas_sub.plan_id).name if saas_sub.present?
  end

  def saas_customers
    customer_count_map = {
      'free_plan' => '[0-100]',
      'starter_plan'=> '[101-1,000]',
      'growth_plan' => '[1,001-5,000]',
      'business_plan' => '[5,001-10,000]',
      'enterprise_plan' => '[10,000+]'
    }
    customer_count_map[saas_plan_name]
  end

  def saas_sub
    platform_user = MerchantCustomer.find_by(customer_id: current_user.id)
    platform_user.subscriptions.active.last
  end
end
