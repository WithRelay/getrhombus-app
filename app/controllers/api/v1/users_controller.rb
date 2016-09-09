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
		  	if u = User.where(email: params[:user][:email]).present?
		  		response = "User already exists."	
		  		status = 409	  	
		  	else 
		  		params[:user][:password] = Toolbox::StringGen.generate_random_string(8)
		  		params[:user][:user_level] = 0
		  		u = User.create(api_v1_user_params)
          # need to add customer's uri here
		  		response = 'User created'
		  		status = 200
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
    params.require(:user).permit(:email, :password, :first_name, :last_name, :phone_number,
      :card_name, :exp_month, :exp_year, :card_token, :card_type, , :user_level,
      # redo relationships here
      #:people_
      address_attributes: [:street_address, :state_province, :city, :country])
  end


end