class Api::V1::PlansController < API::V1::BaseController

  def check_plan_name
    res = current_user.plans.where("lower(name) = ?", params[:plan][:name].downcase)
    if res.empty?
      render json: { valid: true }.to_json
    end
    # need to still render json response if res isn't empty
  end
end
