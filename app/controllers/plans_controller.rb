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
    create_response =  @plan.create_plan({ team: current_user })
    if create_response[0]  #@plan.save
      redirect_to user_plans_path,  flash: { notice: 'Plan was created'}      #respond_with(@plan)
    elsif create_response[0] == false
      @plan.delete
      flash[:error] =  create_response[1][:message]
      render :new
    else
      @plan.delete
      flash[:error] = 'Something went wrong'
      render :new
    end
  end

  def update
    update_response = @plan.update_plan(params, { team: current_user })
    if update_response[0].class == Stripe::Plan
      @plan.update(update_response[1])
      redirect_to user_plans_path, flash: { notice: 'Plan was updated'}
    elsif update_response[0][0] == false
      flash[:error] =  update_response[0][1][:message]
      render :new
    else
      flash[:error] =  'Something went wrong'
      render :new
    end
  end

  def destroy
    unless Subscription.exists?(plan_id: @plan.id)
      delete_response = @plan.delete_plan
      if delete_response[0]
        @plan.delete
        redirect_to user_plans_path, flash: { notice: 'Plan was deleted'}
      elsif delete_response[0] == false
        redirect_to user_plans_path, flash: { error: delete_response[1][:message] }
      else
        redirect_to user_plans_path, flash: { error: 'Something went wrong'}
      end
    else
      redirect_to user_plans_path, flash: { warning: 'You can\'t delete this plan...'}
    end
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
        plan['user_id'] = current_user.id
      }
    end
end
