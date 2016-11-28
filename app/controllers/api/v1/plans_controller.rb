class Api::V1::PlansController < API::V1::BaseController

  def check_plan_name
    res = current_user.plans.where("lower(name) = ?", params[:plan][:name].downcase)
    render json: { valid: res.empty? }
  end

  def get_plan
    begin
      if params[:name]
        res = current_user.plans.where("lower(name) like ?", "%#{params[:name].downcase}%")
      else
        res = current_user.plans
      end
      render json: { "plans" => res }, status: 200
    rescue StandardError => e
      render json: { error: "Unable to find your Plans" }, status: 500
    end
  end

end
