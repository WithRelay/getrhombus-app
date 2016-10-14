class Api::V1::ListsController < API::V1::BaseController
 
  def index
    begin
      if params[:query]
        res = List.where("lower(name) like ? and user_id = ?", "%#{params[:query].downcase}%", current_user.id)
      else
        res = List.where(user_id: current_user.id)
      end

      render json: { "lists" => res }, status: 200
    rescue StandardError => e
      render json: { error: "Unable to find your lists" }, status: 500
    end
  end

end
