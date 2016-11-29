class SubscriptionsController < ApplicationController
  before_action :set_subscription, only: [:show, :edit, :update, :destroy]

  respond_to :html

  def index
    # This is for merchants only for now
    merchant_customers = current_user.customers.pluck(:id)
    @subscriptions = Subscription.where(merchant_customer_id: merchant_customers)
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
    success = false
    card_error = ''
    res = []
    subscription_params[:plan_id].each do |pid|
      subscription_param = subscription_params
      # use single plan id at a time
      subscription_param[:plan_id] = pid
      merchant_customer = MerchantCustomer.find subscription_params[:merchant_customer_id]

      @subscription = merchant_customer.subscriptions.new(subscription_param)
      res = @subscription.create_subscription({ team: current_user, customer: merchant_customer.stripe_customer_id })
      if res.first
        success = true
      else
       success = false
       break
      end
    end
    if success
      redirect_to user_subscriptions_path, flash: {notice: 'Subscriptions created successfully'}
    else
      flash[:error] = (res.second == 'card_error') ? res.third : 'Something went wrong'
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

  private
    def set_subscription
      @subscription = Subscription.find(params[:id])
    end

    def subscription_params
      params.require(:subscription).permit(:quantity, :plan_id, :coupon_id, :merchant_customer_id).tap{ |subscription|
        subscription[:plan_id] = subscription[:plan_id].split(',') if subscription[:plan_id]
      }
    end
end
