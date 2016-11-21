class SubscriptionsController < ApplicationController
  before_action :set_subscription, only: [:show, :edit, :update, :destroy]

  respond_to :html

  # seems to be pulling for everyone
  def index
    #str = current_user.user_level == 1 ? "user_id = " : "team_id = " + current_user.id
    merchant_customer = current_user.merchant.pluck(:id)
    @subscriptions = Subscription.where(merchant_customer_id: merchant_customer)
    #@subscriptions = Subscription.where("where " + str)
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

    dummy_customer = [
      {id: 23, customer_uri: 'cus_9ZBBnoG8jv2ABe', email: '<redacted_email>'},
      {id: 63, customer_uri: 'cus_6D3r30LunmvQXk', email: '<redacted_email>'},
      {id: 60, customer_uri: 'cus_9Z9nHEqdsRbbpZ', email: '<redacted_email>'}
    ]

    res = false
    subscription_params[:merchant_customer_id].each do |cid|
      subscription_params[:plan_id].each do |pid|

        subscription_param = subscription_params
        subscription_param[:merchant_customer_id] = cid
        subscription_param[:plan_id] = pid
         @subscription = Subscription.new(subscription_param)
         # customer = User.find_by id: self.user_id
         #for testing
         customer = {}
         dummy_customer.each do |h|
          customer = h if h[:id] == @subscription.merchant_customer_id
        end

        if customer && @subscription.create_subscription({ team: current_user, customer: customer })  #@subscription.save
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
