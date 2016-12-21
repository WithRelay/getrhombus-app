class SubscriptionsController < ApplicationController
  before_action :set_subscription, only: [:show, :edit, :update, :destroy, :upgrading_subscription, :downgrading_subscription]

  respond_to :html

  include Transactionable

  def index
    # This is for merchants only for now
    merchant_customers = current_user.customers.pluck(:id)
    @subscriptions = Subscription.where(merchant_customer_id: merchant_customers)
                                        .where.not(status: 'canceled')
    respond_with(@subscriptions)
  end

  def show
    respond_with(@subscription)
  end

  def edit
  end

  def create
    @subscription = Subscription.create(subscription_params)
    res = @subscription.create_subscription({ team: current_user })
    if res.first
      redirect_to user_subscriptions_path, flash: {notice: 'Subscription created successfully'}
    else
      @subscription.destroy
      if @subscription.errors.messages.present?
        error = @subscription.errors.full_messages
        flash[:error] = error
      else
        flash[:error] = (res.second == 'card_error') ? res.third : 'Something went wrong'
      end
      redirect_to new_user_subscription_path
    end
  end

  # def update
  #   @subscription.update(subscription_params)
  #   respond_with(@subscription)
  # end

  def destroy
    if @subscription.cancel_subscription(current_user)
      flash[:notice] = 'Your subscription will been canceled at period end.'
      redirect_to user_subscriptions_path
    else
      flash[:error] = 'We couldn\'t cancel your subscription'
    end
  end

  def upgrading_subscription
    res = create_coupon(unused_amount)
    # move user to new subscription based on the new plan selected
    subscription = Subscription.new(
      plan_id: params[:subscription][:plan_id],
      coupon_id: res.second,
      merchant_customer_id: @subscription.merchant_customer_id,
      quantity: @subscription.quantity
    )
    if res.first && subscription.create_subscription({ team: current_user }).first
      @subscription.cancel_subscription(current_user, false)
      flash[:notice] = 'Subscription upgraded successfully.'
    else
      # delete new coupon if subscription is not upgraded/created
      (Coupon.find res.second).destroy if res.first
      flash[:error] = 'Something went wrong.'
    end
    redirect_to user_subscriptions_path
  end

  def downgrading_subscription
    if @subscription.cancel_subscription(current_user)
      # Store new plan that user wants to downgrade to
      store_next_plan(params[:subscription][:plan_id])
      flash[:notice] = 'Subscription listed for downgrade successfully.'
    else
      flash[:error] = 'Something went wrong.'
    end
    redirect_to user_subscriptions_path
  end


  private
    def set_subscription
      @subscription = Subscription.find(params[:id])
    end

    def subscription_params
      params.require(:subscription).permit(:quantity, :plan_id, :coupon_id, :merchant_customer_id)
    end

    # create discount coupon with remaining unused amount while
    # user upgrade subscription before finishing time interval
    def create_coupon(unused_amount)
      coupon = Coupon.new(name: generate_coupon_name, amount_off: unused_amount, duration: 'once')
      if coupon.create_coupon({team: current_user})
        [true, coupon.id]
      else
        coupon.destroy
        [false]
      end
    end

    def unused_amount
      plan = Plan.find @subscription.plan_id
      total_amount = plan.amount
      plan_interval = (plan.interval == 'day') ? plan.interval_count :
                                        ((plan.interval == 'week') ? plan.interval_count*7 : plan.interval_count*30)

      used_amount = ((Time.current.to_i - @subscription.current_period_start)/1.days) * total_amount / plan_interval
      unused_amount = total_amount - used_amount
    end

    def unused_amount
      plan = @subscription.plan
      plan_amt = plan.amount
      coupon_amt = 0

      # calculate coupon amount
      if @subscription.coupon.present?
        if @subscription.amount_off.present?
          coupon_amt = plan_amt - @subscription.amount_off
        else
          coupon_amt = plan_amt - (@subscription.percent_off/100.to_f * plan_amt).round(2)
        end
      end

      # amount after coupon discount
      plan_amt = plan_amt - coupon_amt

      # calculate number of days from subscription start to subscription end
      # stripe most likely stores time in UTC
      start_date = DateTime.strptime(@subscription.current_period_start.to_s,'%s')
      end_date = DateTime.strptime(@subscription.current_period_end.to_s,'%s')
      total_days = (end_date - start_date).to_i + 1  # +1 to include the start day

      days_remaining = (end_date - DateTime.now.utc).to_i
      days_remaining = (days_remaining > 0) ? days_remaining : 0

      plan_amt = (plan_amt.to_f / total_days).round(2)          # plan amount per day
      (plan_amt * days_remaining).round(2)                      # unspent amount (prorated per day)

      # next steps
      # create coupon only if this method is greater than 0.0
    end

    def store_next_plan(plan_id)
      user_id = (MerchantCustomer.find @subscription.merchant_customer_id).merchant_id
      NextPlan.create(user_id: user_id, plan_id: plan_id, status: true)
    end
end
