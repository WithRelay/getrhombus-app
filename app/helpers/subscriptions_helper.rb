module SubscriptionsHelper

  def saas_sub
    @saas_sub = current_user.get_saas_subscription
  end

  def get_saas_sub_id
    @saas_sub.id if current_user.is_merchant? && @saas_sub.present?
  end

  def get_saas_plan_amount
    (Plan.find @saas_sub.plan_id).amount/100 if current_user.is_merchant? && @saas_sub.present?
  end

  def saas_plan_name
    (Plan.find @saas_sub.plan_id).name if @saas_sub.present?
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
    unless @saas_sub.nil?
      start_date = @saas_sub.current_period_start.present? ? Time.zone.at(@saas_sub.current_period_start).strftime("%B %d, %Y") : ''
      end_date = saas_sub.current_period_end.present? ? Time.zone.at(@saas_sub.current_period_end).strftime("%B %d, %Y") : ''
      "Time period: #{start_date} - #{end_date} (#{@saas_sub.plan.interval})"
    end
  end

  def subscription_plan_amount
    "Plan amount: <strong>$#{get_saas_plan_amount}</strong> USD/year".html_safe
  end

  def subscription_customer_count
    "You are currently on the #{saas_plan_name.try(:humanize)}: #{saas_customers} customers"
  end

  def saas_coupon
    @coupon = @saas_sub.coupon
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
    today_invoices = Invoice.where(team_id: current_user.id, paid: true)
      .where("date >= ?", Time.zone.now.beginning_of_day.to_i).pluck(:total, :application_fee)
    yesterday_invoices = Invoice.where(team_id: current_user.id, paid: true)
    .where("date < ? && date >= ?", (Time.zone.now.beginning_of_day).to_i, (Time.zone.now.beginning_of_day - 1.days).to_i).pluck(:total, :application_fee)
    @saas_invoices = [today_invoices, yesterday_invoices]
    @saas_invoices
  end

  def transaction_change
    tday_txns_count = @saas_invoices[0].count
    yday_txns_count = @saas_invoices[1].count
    percent_change = (tday_txns_count - yday_txns_count).to_f/yday_txns_count * 100 if yday_txns_count > 0
    display_change(percent_change.round)
  end

  def total_amount
    @tday_txns_amount = 0
    @saas_invoices[0].each{|arr| @tday_txns_amount += arr[0] }
    @tday_txns_amount/100
  end

  def total_amount_change
    @yday_txns_amount = 0
    @saas_invoices[1].each{|arr| @yday_txns_amount += arr[0] }
    percent_change = (@tday_txns_amount - @yday_txns_amount).to_f/@yday_txns_amount * 100 if @yday_txns_amount > 0
    display_change(percent_change.round)
  end

  def net_sales
    @tday_net_sale = 0
    @saas_invoices[0].each{|arr| @tday_net_sale += (arr[0] - arr[1])}
    @tday_net_sale/100
  end

  def net_sales_change
    @yday_net_sale = 0
    @saas_invoices[1].each{|arr| @yday_net_sale += (arr[0] - arr[1])}
    percent_change = (@tday_net_sale - @yday_net_sale).to_f/@yday_net_sale * 100 if @yday_net_sale > 0
    display_change(percent_change.round)
  end

  def display_change(percent_change)
    if percent_change > 0
      "Up #{percent_change}%\ from yesterday"
    elsif percent_change < 0
      "Down #{percent_change}%\ from yesterday"
    else
      "-"
    end
  end

end
