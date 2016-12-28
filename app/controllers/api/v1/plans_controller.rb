class Api::V1::PlansController < API::V1::BaseController

  def check_plan_name
    res = current_user.merchant_plans.where("lower(name) = ?", params[:plan][:name].downcase)
    render json: { valid: res.blank? }
  end

  def index
    begin
      if params[:name]
        res = current_user.merchant_plans.where("lower(name) like ?", "%#{params[:name].downcase}%")
      else
        res = current_user.merchant_plans
      end
      render json: { "plans" => res }, status: 200
    rescue StandardError => e
      render json: { error: "Unable to find your Plans" }, status: 500
    end
  end

  # create plans from modal
  def create
    begin
      status = 500
      @plan = Plan.new(plan_params)
      if @plan.create_plan({ team: current_user })
        response = 'Plan created successfully'
        status = 200
      else
        response = @plan.errors.messages.present? ? @plan.errors.full_messages : 'Something went wrong'
        @plan.destroy     # revoke created plan on error
      end
    rescue StandardError => e
      response = 'Something went wrong on our end.'
    end
    render json: { response: response }, status: status
  end

  private

  def plan_params
    params.require(:plan).permit(:interval, :name, :amount, :trial_period_days).tap{ |plan|
      # round - deal with inaccurate floating point math. see 100 * 1.1
      plan[:amount] = (100 * plan[:amount].to_f).round if plan[:amount].present?
      interval_ary = plan[:interval].split("_")
      plan[:interval] = interval_ary[0]
      plan[:interval_count] = interval_ary[1]
    }
  end

end
