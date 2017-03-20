class Api::V1::MerchantCustomersController < API::V1::BaseController

  # this is really customers with valid payment info, since they are the ones that can be charged
  def customers
    begin
      customers =  MerchantCustomer.joins(:customer)
                  .select("merchant_customers.id, email, merchant_customers.stripe_customer_id")
                  .where('exp_year >= && exp_month >= ?', Time.current.year, Time.current.month)
                  .where("email like ? or card_name like ? or phone_number like ?", "%#{params[:query].downcase}%", "%#{params[:query].downcase}%", "%#{params[:query].downcase}%")
                  .where("merchant_customers.merchant_id = ?", current_user.id)

      render json: { "customers" => customers }, status: 200
    rescue StandardError => e
      render json: { error: "Unable to find your Customers" }, status: 500
    end
  end

  # all customers - with or without payment info
  def index
  end

end
