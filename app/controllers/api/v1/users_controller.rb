class Api::V1::UsersController < API::V1::BaseController

	def find
		sql = ActiveRecord::Base.send(:sanitize_sql_array, 
				["SELECT users.card_name, users.phone_number FROM 
					( SELECT user_id_from as usersID FROM messages where messages.user_id_to = ?
    				  union
					  SELECT user_id_to as usersID FROM messages where messages.user_id_from = ? 
					) t1
					inner join users on t1.usersID = users.id where lower(card_name) LIKE concat('%', ?, '%') or 
					phone_number like concat('%', ?, '%')", current_user.id, current_user.id, params[:query].downcase, params[:query] ])

		results = User.connection.select_all(sql)

		render json: { "users" => results } and return if results.empty?

		users_array = []
		
		results.each do |u|			
			users_array.push({ phone_number: u["phone_number"], card_name: u['card_name'] })
		end

		render json: { "users" => users_array }
	end


	def add_customers
		# need to start storing number type in user model and change below
		# add zip_code to db
		
		begin
			num_reach = TextingService.twilio_list[current_user.country.to_sym][:types][:local][:reach]
	    if params[:format] == 'csv'
		    render json: { response: current_user.upload_customer_csv(params['csv'].tempfile, num_reach) }, status: 200
		  else
		  	render json: { response: 'Request is not supported.' }, status: 405
		  end
		rescue StandardError => e
			render json: { response: 'Something went wrong on our end.' }, status: 500
		end
  end


end