class Api::V1::MerchantCustomersController < API::V1::BaseController

  def index
    begin
      q = "%#{params[:query].downcase}%"
      customers =  MerchantCustomer.joins(:customer)
                  .select("merchant_customers.id, email, phone_number, card_name")
                  .where("email like ? or card_name like ? or phone_number like ?", q, q, q)
                  .where("merchant_customers.merchant_id = ?", current_user.id)

      render json: { "customers" => customers }, status: 200
    rescue StandardError => e
      render json: { error: "Unable to find your Customers" }, status: 500
    end
  end

end
