class SubscriptionsController < ApplicationController
  before_action :set_subscription, only: [:show, :edit, :update, :destroy]

  respond_to :html

  # seems to be pulling for everyone
  def index
    #str = current_user.user_level == 1 ? "user_id = " : "team_id = " + current_user.id
    @subscriptions = Subscription.where(team_id: current_user.id)
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
      {id: 23, customer_uri: 'cus_9K8ztWi3nEDOJQ', email: '<redacted_email>'},
      {id: 64, customer_uri: 'cus_9J62zWAfp3cHCf', email: '<redacted_email>'},
      {id: 63, customer_uri: 'cus_8ePuK9YNuqOPgz', email: '<redacted_email>'},
      {id: 61, customer_uri: 'cus_8MCWRO4CGwCEvo', email: '<redacted_email>'},
      {id: 60, customer_uri: 'cus_6gcoumphxCETya', email: '<redacted_email>'},
      {id: 62, customer_uri: 'cus_9XiWUXYm5I72Bw', email: '<redacted_email>'}
    ]

    res = false
    subscription_params[:user_id].each do |uid|
      subscription_params[:plan_id].each do |pid|

        subscription_param = subscription_params
        subscription_param[:user_id] = uid
        subscription_param[:plan_id] = pid
         @subscription = Subscription.new(subscription_param)
         # customer = User.find_by id: self.user_id
         #for testing
         customer = {}
         dummy_customer.each do |h|
          customer = h if h[:id] == @subscription.user_id
        end

         @subscription.team_id = current_user.id

         if customer && @subscription.create_subscription({ team: current_user, customer: customer })  #@subscription.save
           res = true# redirect_to user_subscriptions_path       #respond_with(@subscription)
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
    if (@subscription.cancel_subscription(current_user))
      @subscription.destroy
      flash[:notice] = 'Your subscription has been canceled.'
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
      params.require(:subscription).permit(:quantity, :plan_id, :coupon_id, :user_id).tap{ |subscription|
        subscription[:plan_id] = subscription[:plan_id].split(',') if subscription[:plan_id]
        subscription[:user_id] = subscription[:user_id].split(',') if subscription[:user_id]
      }
    end
end
