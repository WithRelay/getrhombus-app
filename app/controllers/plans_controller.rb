class PlansController < ApplicationController
  before_action :set_plan, only: [:show, :edit, :update, :destroy]
  respond_to :html, :js

  def index
    # get subscription id to use to determing if destroy link should show up
    @plans = current_user.plans
              .joins("LEFT JOIN subscriptions s ON s.plan_id = plans.id")
              .select('plans.id, amount, plans.name, currency, plans.interval, interval_count, s.id as subscription_id')
              .paginate(page: params[:page], per_page: 1)
              .order('plans.created_at DESC')
              
    respond_with(@plans)
  end

  def show
    respond_with(@plan)
  end

  def new
    @plan = Plan.new
    respond_with(@plan)
  end

  def edit
  end

  def create
    @plan = Plan.new(plan_params)

    if @plan.create_plan({ team: current_user })
      redirect_to user_plans_path,  flash: { notice: 'Plan was created' }      #respond_with(@plan)
    else
      @plan.delete     # revoke created plan on error
      flash[:error] = "We couldn't create the plan" 
      render :new  
    end
  end

  def update
    hash = params.require(:plan).permit(:name)
    if @plan.update_plan(hash, current_user)
      redirect_to user_plans_path, flash: { notice: 'Plan was updated' }
    else
      flash[:error] =  "We couldn't update the plan"
      redirect_to edit_user_plan_path
    end
  end

  def destroy
    unless Subscription.exists?(plan_id: @plan.id)
      if @plan.delete_plan(current_user)
        @plan.delete
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

    def plan_params
      params.require(:plan).permit(:interval, :name, :amount).tap{ |plan|
        if params[:plan][:interval_month]
          plan['interval_count'] = params[:plan][:interval_month]
        elsif params[:plan][:interval_week]
          plan['interval_count'] = params[:plan][:interval_week]
        else
          plan['interval_count'] = params[:plan][:interval_count]
        end
      }
    end
end
