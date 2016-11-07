class SubscriptionsController < ApplicationController
  before_action :set_subscription, only: [:show, :edit, :update, :destroy]

  respond_to :html

  # seems to be pulling for everyone
  def index
    #str = current_user.user_level == 1 ? "user_id = " : "team_id = " + current_user.id
    @subscriptions = Subscription.all
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
    @subscription = Subscription.new(subscription_params)
    u = User.find_by id: self.user_id
    @subscription.team_id = current_user.id
    if u && @subscription.create_subscription({ team: current_user, customer: u.customer_uri })  #@subscription.save
      redirect_to user_subscriptions_path       #respond_with(@subscription)
    else
      respond_with(@subscription)
    end
  end

  def update
    @subscription.update(subscription_params)
    respond_with(@subscription)
  end

  def destroy
    @subscription.cancel_subscription(true)
    #@subscription.destroy
    flash[:notice] = 'Canceled'
    redirect_to user_subscriptions_path         #respond_with(@subscription)
  end

  private
    def set_subscription
      @subscription = Subscription.find(params[:id])
    end

    def subscription_params
      params.require(:subscription).permit(:quantity, :plan_id, :user_id)
    end
end
