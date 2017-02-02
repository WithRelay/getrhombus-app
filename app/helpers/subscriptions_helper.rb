module SubscriptionsHelper
  def get_saas_sub_id
    saas_sub.id if current_user.is_merchant? && saas_sub.present?
  end

  def get_saas_plan_amount
    (Plan.find saas_sub.plan_id).amount/100 if current_user.is_merchant? && saas_sub.present?
  end

  def saas_sub
    platform_user = MerchantCustomer.find_by(customer_id: current_user.id)
    platform_user.subscriptions.where(status: 'active').last
  end
end
