class SubscriptionsController < ApplicationController
  before_action :set_subscription, only: [:show, :edit, :update, :destroy]

  respond_to :html

  # seems to be pulling for everyone
  def index
    #str = current_user.user_level == 1 ? "user_id = " : "team_id = " + current_user.id
    #@subscriptions = Subscription.where("where " + str)
    merchant_customer = current_user.merchant.pluck(:id)
    @subscriptions = Subscription.where(merchant_customer_id: merchant_customer)
    respond_with(@subscriptions)
  end

  def show
    respond_with(@subscription)
  end

  def new
    @subscription = Subscription.new
    respond_with(@subscription)
  end

  def edit
  end

  def create
    res = false
    subscription_params[:merchant_customer_id].each do |cid|
      subscription_params[:plan_id].each do |pid|

        subscription_param = subscription_params
        subscription_param[:merchant_customer_id] = cid
        subscription_param[:plan_id] = pid
        merchant_customer = MerchantCustomer.find cid

        @subscription = merchant_customer.subscriptions.new(subscription_param)
        if merchant_customer && @subscription.create_subscription({ team: current_user, customer: merchant_customer.stripe_customer_id })  #@subscription.save
          res = true
        else
         res = false
         break
        end
      end
    end

    if res
      redirect_to user_subscriptions_path, flash: {notice: 'Subscriptions created successfully'}
    else
      flash[:error] = 'Something went wrong'
      redirect_to new_user_subscription_path
    end

  end

  # def update
  #   @subscription.update(subscription_params)
  #   respond_with(@subscription)
  # end

  def destroy
    res = @subscription.cancel_subscription(current_user)
    if (res.first)
      @subscription.update(
        status: res.second.status,
        cancel_at_period_end: res.second.cancel_at_period_end
      )
      if @subscription.cancel_at_period_end
        flash[:notice] = 'Your subscription has been canceled at period end.'
      else
        flash[:notice] = 'Your subscription has been canceled.'
      end
      redirect_to user_subscriptions_path         #respond_with(@subscription)
    else
      flash[:error] = 'We could\'t cancel your subscription'
    end
  end

  private
    def set_subscription
      @subscription = Subscription.find(params[:id])
    end

    def subscription_params
      params.require(:subscription).permit(:quantity, :plan_id, :coupon_id, :merchant_customer_id).tap{ |subscription|
        subscription[:plan_id] = subscription[:plan_id].split(',') if subscription[:plan_id]
        subscription[:merchant_customer_id] = subscription[:merchant_customer_id].split(',') if subscription[:merchant_customer_id]
      }
    end
end
