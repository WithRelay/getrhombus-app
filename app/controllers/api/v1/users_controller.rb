class Api::V1::UsersController < API::V1::BaseController

	def find
		sql = ActiveRecord::Base.send(:sanitize_sql_array, 
				["SELECT users.card_name, users.phone_number FROM 
					( SELECT user_id as usersID FROM messages where messages.user_id_to = ?
    				  union
					  SELECT user_id_to as usersID FROM messages where messages.user_id = ? 
					) t1
					inner join users on t1.usersID = users.id where lower(card_name) LIKE concat('%', ?, '%') or 
					phone_number like concat('%', ?, '%') and instrument_uri is not null", current_user.id, current_user.id, params[:query].downcase, params[:query] ])

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
		  	if User.where(email: params[:user][:email]).present?
		  		response = "User already exists."	
		  		status = 409	  	
		  	else 
		  		params[:user][:password] = Toolbox::StringGen.generate_random_string(8)
		  		params[:user][:user_level] = 0
		  		User.create(api_v1_user_params)
		  		response = 'User created'
		  		status = 200
		  	end		  	
		  end
		rescue StandardError => e
			 response = 'Something went wrong on our end.'
		end
		render json: { response: response }, status: status
  end

  private

  def api_v1_user_params
    params.require(:user).permit(:email, :password, :first_name, :last_name, :phone_number,
      :card_name, :expiration_month, :expiration_year, :instrument_uri, :card_type, :street_address,
      :state_province, :country, :user_level)
  end


end