class Api::V1::CustomersController < API::V1::BaseController
  def customer_data
    dummy_customer = [
      {id: 23, customer_uri: 'cus_9ZBBnoG8jv2ABe', email: '<redacted_email>'},
      {id: 63, customer_uri: 'cus_6D3r30LunmvQXk', email: '<redacted_email>'},
      {id: 60, customer_uri: 'cus_9Z9nHEqdsRbbpZ', email: '<redacted_email>'}
    ]
    begin
      if params[:email]
        res = []
        dummy_customer.each do |h|
          res << h if h[:email].include? params[:email]
        end
      else
        res = dummy_customer
      end
      render json: { "customers" => res }, status: 200
    rescue StandardError => e
      render json: { error: "Unable to find your Customers" }, status: 500
    end
  end
end
