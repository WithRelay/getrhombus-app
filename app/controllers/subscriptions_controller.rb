class SubscriptionsController < ApplicationController
  include DashboardNotification
  before_action :set_notifications
  before_action :set_subscription, only: [:show, :edit, :update]

  respond_to :html

  def index
    @subscriptions = Subscription.includes(merchant_customer: [:customer]).includes(:plan, :coupon)
                                      .where.not(status: 'canceled')
                                      .where('merchant_customers.merchant_id' => current_user.id)
                                      .where.not('merchant_customers.stripe_customer_id' => [nil, ""])
                                      .paginate(page: params[:page], per_page: 10)
                                      .order(created_at: :desc)
    @plan = Plan.new
  end

  def show
    respond_with(@subscription)
  end

  def edit
  end

  def update
  end

  private

    def set_subscription
      @subscription = Subscription.find(params[:id])
    end

end



=begin
    ### FOR SUBSCRIPTION UPGRADE/DOWNGRADE. LEAVE THIS FOR LATER

    ###

    def set_subscription
      @subscription = if params[:action] == 'upgrade_subscription' || params[:action] == 'downgrade_subscription'
        Subscription.find(params[:subscription][:subscription_id])
      else
        Subscription.find(params[:id])
      end
    end

    # create discount coupon with remaining unused amount while
    # user upgrade subscription before finishing time interval
    include Transactionable
    def create_coupon(amt)
      @coupon = Coupon.new(name: generate_resource_name("Coupon"), amount_off: amt, duration: 'once')
      if @coupon.create_coupon({team: current_user})
        [true, @coupon.id]
      else
        @coupon.destroy
        [false]
      end
    end

    def get_plan_id
      plan = Plan.find_by(name: params[:subscription][:plan_name], merchant_id: User.get_platform_acct_obj.id)
      plan.id if plan
    end

    def store_next_plan(plan_id)
      # merchant is platform customer in MerchantCustomer
      user_id = (MerchantCustomer.find @subscription.merchant_customer_id).customer_id
      NextPlan.create(user_id: user_id, plan_id: plan_id, status: true)
    end

    def upgrade_subscription
      amount = @subscription.unused_amount
      coupon_res = [true] if amount == 0
      # coupon only created if amount is valid ie. > 0
      # if coupon create coupon_res is coupon id otherwise false
      coupon_res = create_coupon(amount) if amount > 0
      # move user to new subscription based on the new plan selected
      new_subscription = Subscription.new(
        plan_id: get_plan_id,
        coupon_id: coupon_res.second,
        merchant_customer_id: @subscription.merchant_customer_id,
        quantity: @subscription.quantity
      )
      # upgrade subscription only if unused amount not present and
      # while coupon successfully created with unused amount
      if coupon_res.first && new_subscription.create_subscription({ team: current_user }).first
        @subscription.cancel_subscription(current_user, false)
        current_user.next_plans.update_all(status: false)
        flash[:notice] = 'Subscription upgraded successfully.'
      else
        # what about card errors here
        # delete new coupon if subscription is not upgraded/created
        @coupon.destroy if coupon_res
        flash[:error] = 'Something went wrong.'
      end
      redirect_to user_subscriptions_path
    end

    def downgrade_subscription
      if @subscription.cancel_subscription(current_user)
        current_user.next_plans.update_all(status: false)
        # Store new plan that user wants to downgrade to
        store_next_plan(get_plan_id)
        flash[:notice] = 'Subscription listed for downgrade successfully.'
      else
        flash[:error] = 'Something went wrong.'
      end
      redirect_to user_subscriptions_path
    end
=end
