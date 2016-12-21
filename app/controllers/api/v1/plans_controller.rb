class Api::V1::PlansController < API::V1::BaseController

  def check_plan_name
    res = current_user.merchant_plans.where("lower(name) = ?", params[:plan][:name].downcase)
    render json: { valid: res.empty? }
  end

  def get_plan
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
  def add_plan
    begin
      status = 500
      plan = Plan.new(
                  interval: 'day', name: params['Plan-name'],
                  amount: (100 * params['Plan-Amount'].to_f).round,
                  interval_count: params['Plan-Interval']
                )
      if plan.create_plan({ team: current_user })
        response = 'Plan created successfully'
        status = 200
      else
        response = 'Something went wrong.'
        status = 409
      end
    rescue StandardError => e
      response = 'Something went wrong on our end.'
    end
    render json: { response: response }, status: status
  end

end
