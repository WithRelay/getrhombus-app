class PlansController < ApplicationController
  before_action :set_plan, only: [:show, :edit, :update, :destroy]
  respond_to :html, :js

  def index
    @plans = current_user.plans.paginate(page: params[:page], per_page: 25).order('updated_at DESC')
    # @plans = Plan.all
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
    @plan.user_id = current_user.id
    if @plan.create_plan({ team: current_user })  #@plan.save
      redirect_to user_plans_path       #respond_with(@plan)
    else
      respond_with(@plan)
    end
  end

  def update
    # res = PaymentService.update_plan(@plan.id, plan_params[:name])
    @plan.update(params.require(:plan).permit(:name))
    redirect_to user_plans_path, flash: { notice: 'Plan was updated'}
  end

  def destroy
    # res = PaymentService.delete_plan(@plan.id)
    @plan.destroy
    redirect_to user_plans_path, flash: { notice: 'Plan was deleted'}
  end

  private
    def set_plan
      @plan = Plan.find(params[:id])
    end

    def plan_params
      params.require(:plan).permit(:amount, :interval, :name).tap{ |plan|
        if params[:plan][:interval_month]
          plan['interval_count'] = params[:plan][:interval_month]
        elsif params[:plan][:interval_week]
          plan['interval_count'] = params[:plan][:interval_week]
        else
          plan['interval_count'] = params[:plan][:interval_count]
        end
        # since amount is in cent
        plan['amount'] = 100 * plan['amount'].to_f
        plan['currency'] = current_user.currency
      }
    end
end
