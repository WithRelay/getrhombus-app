module SubscriptionsHelper

  def saas_sub
    current_user.get_saas_subscription
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
      'PlanA' => '[0-100]',
      'PlanB'=> '[101-1,000]',
      'PlanC' => '[1,001-2,500]',
      'PlanD' => '[2,501-5,000]',
      'PlanE' => '[5,001-7,500]',
      'PlanF' => '[7,501-10,000]',
      'PlanG' => '[10,001-15,000]',
      'PlanH' => '[15,001-20,000]',
      'PlanI' => '[20,001-30,000]',
      'PlanJ' => '[30,001-35,000]',
      'PlanK' => '[35,001-40,000]',
      'PlanL' => '[40,001-45,000]',
      'PlanM' => '[45,001-50,000]'
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

  def saas_invoices
    invoices = []
    current_user.customers.each do |cus|
      invoices += cus.invoices
    end
    invoices
  end

  def invoices_count
    today_count = 0
    yesterday_count = 0
    saas_invoices.each do |i|
      today_count += 1 if Time.zone.at(i.date).today?
      yesterday_count += 1 if (Time.zone.at(i.date) + 1.days).today?
    end
    [today_count, yesterday_count]
  end

  def total_invoices_amount
    today_amount = 0
    yesterday_amount = 0
    saas_invoices.each do |i|
      today_amount += i.total if Time.zone.at(i.date).today?
      yesterday_amount += i.total if (Time.zone.at(i.date) + 1.days).today?
    end
    [today_amount, yesterday_amount]
  end

  def fees_on_subscription
    fees = 0
    current_user.customers.each do |cus|
      cus.subscriptions.active.each { |i| fees += i.plan.amount}
    end
    fees
  end

  def total_count_change
    count = invoices_count
    "#{(((count[0] - count[1]).to_f/count[0]) * 100).to_i}%"
  end

  def total_amount_changes
    amount = total_invoices_amount
    "#{(((amount[0] - amount[1])/amount[0]) * 100).to_i}%"
  end

end
