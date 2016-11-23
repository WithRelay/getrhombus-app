class SubscriptionPresenter < BasePresenter

  def get_customer_info
    customer = MerchantCustomer.find @model.merchant_customer_id
    user = User.find customer.customer_id
    "#{user.email}"
  end

  def get_plan_info
    plan = Plan.find @model.plan_id
    amount = "%.2f" %(plan.amount.to_f/100)
    interval_count = plan.interval_count
    interval = (interval_count > 1)? (plan.interval.pluralize): plan.interval
    "#{plan.name}(#{plan.currency} #{amount} every #{interval_count} #{interval})"
  end

  def get_coupon_info
    if @model.coupon_id
      coupon = Coupon.find @model.coupon_id
      coupon_name = coupon.name
      discount = "#{coupon.currency} " + "%.2f" %(coupon.amount_off.to_f/100)
      percent_off = "#{coupon.percent_off}%"
      discount = percent_off if coupon.percent_off
      if coupon.duration == 'repeating'
        interval = (coupon.duration_in_months > 1) ? ("months") : "month"
        duration = "for #{coupon.duration_in_months} #{interval}"
      else
        duration = coupon.duration
      end
      "#{coupon_name}: #{discount} #{duration}"
    else
      "No active coupon"
    end
  end

  def status
    if @model.status == 'active'
      "<span class='label label-success'>#{ @model.status}</span>".html_safe
    elsif @model.status == 'canceled'
      "<span class='label label-danger'>#{ @model.status}</span>".html_safe
    else
      "<span class='label label-warning'>#{ @model.status}</span>".html_safe
    end
  end

end
