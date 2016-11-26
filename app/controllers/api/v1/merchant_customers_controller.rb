class Api::V1::MerchantCustomersController < API::V1::BaseController
  def customer_data
    merchant_customers =  MerchantCustomer.joins(:customer)
                            .select("merchant_customers.id, email, merchant_customers.stripe_customer_id")
                            .where('exp_year  > ? || exp_year = ? && exp_month > ?',Time.now.year , Time.now.year, Time.now.month)
                            .where.not(users: { email: current_user.email })

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

  def get_data(merchant_customers)
    data_array = []
    merchant_customers.each do |mc|
      data = {}
      data[:id] = mc.id
      data[:stripe_customer_id] = mc.stripe_customer_id
      data[:email] = mc.email
      data_array << data
    end

    data_array
  end
end
