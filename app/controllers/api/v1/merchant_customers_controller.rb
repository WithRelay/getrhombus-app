class Api::V1::MerchantCustomersController < API::V1::BaseController
  def customer_data
    customers = get_data(MerchantCustomer.where.not(customer_id: nil))
    begin
      if params[:email]
        res = []
        customers.each do |h|
          res << h if h[:email].include? params[:email]
        end
      else
        res = customers
      end
      render json: { "customers" => res }, status: 200
    rescue StandardError => e
      render json: { error: "Unable to find your Customers" }, status: 500
    end
  end

  def get_data(customers)
    data_array = []
    customers.each do |cus|
      data = {}
      data[:id] = cus.id
      data[:stripe_customer_id] = cus.stripe_customer_id
      data[:email] = (User.find cus.customer_id).email
      data_array << data
    end

    data_array
  end
end
