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
    if create_response[0]
      @plan.update(currency: create_response[0].currency,
        stripe_livemode: create_response[0].livemode)
      redirect_to user_plans_path,  flash: { notice: 'Plan was created'}      #respond_with(@plan)
    elsif create_response[0] == false
      @plan.amount = @plan.amount.to_f / 100 #change cent amount
      @plan.delete # revoke created plan on error
      flash[:error] = 'We couldn\'t create the plan'
      render :new
    else
      @plan.amount = @plan.amount.to_f / 100 #change cent amount
      @plan.delete # revoke created plan on error
      flash[:error] = 'Something went wrong'
      render :new
    end
  end

  def update
    update_response = @plan.update_plan(params,current_user)
    if update_response[0].class == Stripe::Plan
      @plan.update(update_response[1])
      redirect_to user_plans_path, flash: { notice: 'Plan was updated'}
    elsif update_response[0][0] == false
      flash[:error] =  'We couldn\'t update the plan'
      redirect_to edit_user_plan_path
    else
      flash[:error] =  'Something went wrong'
      redirect_to edit_user_plan_path
    end
  end

  def destroy
    unless Subscription.exists?(plan_id: @plan.id)
      delete_response = @plan.delete_plan(current_user)
      if delete_response[0]
        @plan.delete
        redirect_to user_plans_path, flash: { notice: 'Plan was deleted'}
      elsif delete_response[0] == false
        redirect_to user_plans_path, flash: { error: 'We couldn\'t delete the plan' }
      else
        redirect_to user_plans_path, flash: { error: 'Something went wrong'}
      end
    else
      redirect_to user_plans_path, flash: { warning: 'You can\'t delete  plan with subscription...'}
    end
  end

  private
    def set_plan
      @plan = Plan.find(params[:id])
    end

    def plan_params
      params.require(:plan).permit(:interval, :name).tap{ |plan|
        if params[:plan][:interval_month]
          plan['interval_count'] = params[:plan][:interval_month]
        elsif params[:plan][:interval_week]
          plan['interval_count'] = params[:plan][:interval_week]
        else
          plan['interval_count'] = params[:plan][:interval_count]
        end
        # since amount is in cent
        plan['amount'] = 100 * params[:plan][:amount].to_f
        plan['user_id'] = current_user.id
      }
    end
end
