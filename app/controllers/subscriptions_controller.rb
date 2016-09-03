class SubscriptionsController < ApplicationController
  before_action :set_subscription, only: [:show, :edit, :update, :destroy]

  respond_to :html

  def index
    @subscriptions = Subscription.all
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
    #flash[:notice] = 'dadadads'
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
