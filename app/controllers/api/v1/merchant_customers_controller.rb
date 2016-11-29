class Api::V1::MerchantCustomersController < API::V1::BaseController
  def customers
    begin
      customers =  MerchantCustomer.joins(:customer)
                  .select("merchant_customers.id, email, merchant_customers.stripe_customer_id")
                  .where('exp_year  > ? || exp_year = ? && exp_month > ?', Time.current.year , Time.current.year, Time.current.month)
                  .where("email like ?", "%#{params[:query].downcase}%")

      render json: { "customers" => customers }, status: 200
    rescue StandardError => e
      render json: { error: "Unable to find your Customers" }, status: 500
    end
  end

end
