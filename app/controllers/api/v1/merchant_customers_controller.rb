class Api::V1::MerchantCustomersController < API::V1::BaseController
  def customers
    begin
      customers =  MerchantCustomer.joins(:customer)
                  .select("merchant_customers.id, email, merchant_customers.stripe_customer_id")
                  .where('exp_year  > ? || exp_year = ? && exp_month >= ?', Time.current.year , Time.current.year, Time.current.month)
                  .where("email like ?", "%#{params[:query].downcase}%")
                  .where("merchant_customers.merchant_id = ?", current_user.id)

      render json: { "customers" => customers }, status: 200
    rescue StandardError => e
      render json: { error: "Unable to find your Customers" }, status: 500
    end
  end

  ## probably can remove this
  def find
    sql = ActiveRecord::Base.send(:sanitize_sql_array,
    ["SELECT users.card_name, users.phone_number FROM
          ( SELECT user_id as usersID FROM messages where messages.user_id_to = ?
              union
            SELECT user_id_to as usersID FROM messages where messages.user_id = ?
          ) t1
          inner join users on t1.usersID = users.id where lower(card_name) LIKE concat('%', ?, '%') or
          phone_number like concat('%', ?, '%') and card_token is not null", current_user.id, current_user.id, params[:query].downcase, params[:query] ])

    results = User.connection.select_all(sql)
    results = results.map { |u| { phone_number: u["phone_number"], card_name: u['card_name'] } }
    render json: { "users" => results }, status: 200
  end

end
