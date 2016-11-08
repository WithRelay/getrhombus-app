class Api::V1::CustomersController < API::V1::BaseController
  def customer_data
    dummy_customer = [
      {id: 1, customer_uri: 'cus_9K8ztWi3nEDOJQ', email: '<redacted_email>'},
      {id: 2, customer_uri: 'cus_9J62zWAfp3cHCf', email: '<redacted_email>'},
      {id: 3, customer_uri: 'cus_8ePuK9YNuqOPgz', email: '<redacted_email>'},
      {id: 4, customer_uri: 'cus_7IEL0v1L6XB3Mc', email: '<redacted_email>'},
      {id: 5, customer_uri: 'cus_8MCWRO4CGwCEvo', email: '<redacted_email>'},
      {id: 6, customer_uri: 'cus_6gcoumphxCETya', email: '<redacted_email>'}
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
