class Api::V1::UsersController < API::V1::BaseController

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

  def add_customers
    begin
      status = 500
      
      if params[:format] == 'csv'
        response = current_user.upload_customer_csv(params['csv'].tempfile)
        status = 200
      elsif params[:format] == 'json'
        # render json: {}, status: 200 and return
        u = User.where(email: params[:user][:email])
        if u.present?
          response = "User already exists."
          status = 409
        else
          params[:user][:password] = Toolbox::StringGen.generate_random_string(8)
          params[:user][:user_level] = 0
          u = User.create(api_v1_user_params)
          if u.errors.present? # if serverside side error occurs it returns true 
            response = u.errors.full_messages
            status = 409
          else
            address = u.build_address(api_v1_address_params)
            address.save
            person = u.people.create(api_v1_person_params)
            params[:user][:lists].split(',').each{ |l| UserList.create(user_id: u.id, list_id:l) }
            # need to add customer's uri here
            response = 'User created'
            status = 200
          end
        end
        Referrer.save_referrer_with_id(current_user.id, u.id)
      end
    rescue StandardError => e
      response = 'Something went wrong on our end.'
    end

    render json: { response: response }, status: status
  end

  private

  def api_v1_user_params
    params.require(:user).permit(:email, :password, :first_name, :last_name, :phone_number,:user_level,
    :card_name, :last4, :exp_month, :exp_year, :card_token, :card_type)
  end

  def api_v1_address_params
    params.require(:user).permit(:street_address, :state_province, :city, :country)
  end

  def api_v1_person_params
    params.require(:user).permit(:first_name, :last_name)
  end

end
