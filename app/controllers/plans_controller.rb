class PlansController < ApplicationController
  before_action :set_plan, only: [:show, :edit, :update, :destroy]

  respond_to :html

  def index
    @plans = Plan.all
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
    @plan.update(plan_params)
    respond_with(@plan)
  end

  def destroy
    @plan.destroy
    respond_with(@plan)
  end

  private
    def set_plan
      @plan = Plan.find(params[:id])
    end

    def plan_params
      params.require(:plan).permit(:amount, :interval, :interval_count, :name)
    end
end
