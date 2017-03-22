class Api::V1::CustomersController < API::V1::BaseController
  def index
    user = User.joins(:merchant_customers).where(id: current_user_id)
                                          .where("email LIKE ? OR card_name LIKE ?", "#{params[:query]}%", "#{params[:query]}%")
                                          .where(merchant_customers: { merchant_id: current_user_id})
    render json: user
  end
end
