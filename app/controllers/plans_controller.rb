class PlansController < ApplicationController
  before_action :set_plan, only: [:show, :destroy]
  respond_to :html, :js

  def index
    # get subscription id to use to determine if destroy link should show up
    @plans = current_user.merchant_plans
              .joins("LEFT JOIN subscriptions s ON s.plan_id = plans.id")
              .select('plans.id, amount, plans.name, currency, plans.interval, interval_count, s.id as subscription_id')
              .paginate(page: params[:page], per_page: 1)
              .order('plans.created_at DESC')

    respond_with(@plans)
  end

  def show
    respond_with(@plan)
  end

  def destroy
    unless Subscription.exists?(plan_id: @plan.id)
      if @plan.delete_plan(current_user)
        @plan.destroy
        redirect_to user_plans_path, flash: { notice: 'Plan was deleted' }
      else
        redirect_to user_plans_path, flash: { error: "We couldn't delete the plan" }
      end
    else
      redirect_to user_plans_path, flash: { warning: "You can't delete plan with subscription..." }
    end
  end

  private
    def set_plan
      @plan = Plan.find(params[:id])
    end

end
