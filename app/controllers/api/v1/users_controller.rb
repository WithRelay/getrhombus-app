class Api::V1::UsersController < API::V1::BaseController

	def find
		sql = ActiveRecord::Base.send(:sanitize_sql_array, 
				["SELECT users.card_name, users.phone_number FROM 
					( SELECT user_id as usersID FROM messages where messages.user_id_to = ?
    				  union
					  SELECT user_id_to as usersID FROM messages where messages.user_id = ? 
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
		begin
	    if params[:format] == 'csv'
		    render json: { response: current_user.upload_customer_csv(params['csv'].tempfile) }, status: 200
		  else
		  	render json: { response: 'Request is not supported.' }, status: 405
		  end
		rescue StandardError => e
			render json: { response: 'Something went wrong on our end.' }, status: 500
		end
  end


end