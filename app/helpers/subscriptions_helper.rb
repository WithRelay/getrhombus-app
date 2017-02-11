module SubscriptionsHelper

  def saas_sub
    platform_user = MerchantCustomer.find_by(customer_id: current_user.id)
    platform_user.subscriptions.active.last
  end

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

  def subscription_time_period
    @saas_sub = saas_sub
    start_date = @saas_sub.current_period_start.present? ? Time.zone.at(@saas_sub.current_period_start).strftime("%B %d, %Y") : ''
    end_date = saas_sub.current_period_end.present? ? Time.zone.at(@saas_sub.current_period_end).strftime("%B %d, %Y") : ''
    "Time period: #{start_date} - #{end_date} (#{@saas_sub.plan.interval})"
  end

  def subscription_plan_amount
    "Plan amount: <strong>$#{get_saas_plan_amount}</strong> USD/year".html_safe
  end

  def subscription_customer_count
    "You are currently on the #{saas_plan_name.humanize}: #{saas_customers} customers"
  end

  def saas_coupon
    @coupon = saas_sub.coupon
    {
      name: @coupon.name.humanize,
      type: saas_coupon_type,
      value: saas_coupon_value,
      duration: saas_coupon_duration,
      end_date: saas_coupon_end_date
    } if @coupon.present?
  end

  def saas_coupon_type
    @coupon.amount_off.present? ? 'Amount' : 'Percentage'
  end

  def saas_coupon_value
     @coupon.amount_off.present? ? "$%.2f"%" #{@coupon.amount_off.to_f/100}" : "#{@coupon.present_off}%"
  end

  def saas_coupon_duration
    "#{@coupon.duration_in_months} months"
  end

  def saas_coupon_end_date
    if @coupon.duration_in_months
      end_date = (@coupon.duration_in_months).months 
      "#{(@saas_sub.created_at + end_date).strftime("%B %d, %Y")}"
    else
      "#{(@saas_sub.created_at).strftime("%B %d, %Y")}"
    end
  end
end
