class Api::V1::MerchantCustomersController < API::V1::BaseController
  def customer_data
    merchant_customers =  MerchantCustomer.joins(:merchant).where.not(users: { card_token: nil, email: current_user.email })
    customers = get_data(merchant_customers)
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

MerchantCustomer.joins(:customers).where.not(users: {card_token: nil, email: '<redacted_email>'})
