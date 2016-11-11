class Api::V1::CustomersController < API::V1::BaseController
  def customer_data
    dummy_customer = [
      {id: 23, customer_uri: 'cus_9K8ztWi3nEDOJQ', email: '<redacted_email>'},
      {id: 64, customer_uri: 'cus_9J62zWAfp3cHCf', email: '<redacted_email>'},
      {id: 63, customer_uri: 'cus_8ePuK9YNuqOPgz', email: '<redacted_email>'},
      {id: 61, customer_uri: 'cus_8MCWRO4CGwCEvo', email: '<redacted_email>'},
      {id: 60, customer_uri: 'cus_6gcoumphxCETya', email: '<redacted_email>'},
      {id: 62, customer_uri: 'cus_9XiWUXYm5I72Bw', email: '<redacted_email>'}#managed customer
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
