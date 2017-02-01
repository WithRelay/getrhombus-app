class SubscriptionPresenter < BasePresenter

  def get_customer_name
    "#{user.first_name} #{user.last_name}"
  end

  def get_plan_name
    plan.name
  end

  def get_amount
    "%.2f" %(plan.amount.to_f/100)
  end

  def get_customer_email
    user.email
  end

  def last4
    user.last4
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

  def user
     User.find customer.customer_id
  end

  def customer
    MerchantCustomer.find @model.merchant_customer_id
  end

  def plan
    Plan.find @model.plan_id
  end

end
