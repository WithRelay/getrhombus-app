class Api::V1::SubscriptionsController < API::V1::BaseController

  def upgrading_subscription
    begin
      status = 500
      @subscription = Subscription.find params[:subscription_id]
      res = create_coupon(unused_amount)
      if res.first && create_subscription(params[:plan_id], res.second)
        cancel_subscription(false)
        response = 'Subscription upgraded successfully.'
        status = 200
      else
        # delete new coupon if subscription is not upgraded/created
        (Coupon.find res.second).destroy
        response = 'Something went wrong.'
        status = 409
      end
    rescue StandardError => e
      response = 'Something went wrong on our end.'
    end
    render json: { response: response }, status: status
  end

  def downgrading_subscription
    begin
      status = 500
      @subscription = Subscription.find params[:subscription_id]
      if cancel_subscription(true)
        # Store new plan that user wants to downgrade to
        store_next_plan(params[:plan_id])
        response = 'Subscription listed for downgrade successfully.'
        status = 200
      else
        response = 'Something went wrong.'
        status = 409
      end
    rescue StandardError => e
      response = 'Something went wrong on our end.'
    end
    render json: { response: response }, status: status
  end

  private
  def unused_amount
    plan = Plan.find @subscription.plan_id
    total_amount = plan.amount
    plan_interval = (plan.interval == 'day') ? plan.interval_count :
                                      ((plan.interval == 'week') ? plan.interval_count*7 : plan.interval_count*30)

    used_amount = ((Time.current.to_i - @subscription.current_period_start)/1.days) * total_amount / plan_interval
    unused_amount = total_amount - used_amount
  end

  # create discount coupon with remaining unused amount while
  # user upgrade subscription before finishing time interval
  def create_coupon(unused_amount)
    # coupon_name = "Coupon-#{Coupon.last.id + 1}"
    # which one is better for creating coupon name ?
    coupon_name =  'Coupon-' + SecureRandom.hex(5)
    coupon = Coupon.new(name: coupon_name,amount_off: unused_amount, duration: 'once')
    if coupon.create_coupon({team: current_user})
      [true, coupon.id]
    else
      coupon.destroy
      [false]
    end
  end

  # move user to new subscription based on the new plan selected
  def create_subscription(new_plan_id, new_coupon_id)
    subscription = Subscription.new(
      plan_id: new_plan_id, coupon_id: new_coupon_id,
      merchant_customer_id: @subscription.merchant_customer_id,
      quantity: @subscription.quantity
    )
    subscription.create_subscription({ team: current_user }).first
  end

  # cancel current subscription immediately after upgrading subscription
  def cancel_subscription(at_period_end )
    if @subscription.cancel_subscription(current_user, at_period_end)
      true
    else
      false
    end
  end

  def store_next_plan(plan_id)
    user_id = (MerchantCustomer.find @subscription.merchant_customer_id).customer_id
    NextPlan.create( user_id: user_id, plan_id: plan_id, status: true)
  end

end
