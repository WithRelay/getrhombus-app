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

  private
    def set_subscription
      @subscription = Subscription.find(params[:id])
    end

    def subscription_params
      params.require(:subscription).permit(:quantity, :plan_id, :coupon_id, :merchant_customer_id)
    end
end
