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


	def add_customers(type='json')
		# need to start storing number type in user model and change below
		# add zip_code to db
		begin
			num_reach = TextingService.twilio_list[current_user.country.to_sym][:types][:local][:reach]
	    if params[:format] == 'csv'
	    	headers_checked = false
	    	response = []
		    headers = [:first_name, :last_name, :email, :phone_number, :street_address, :city, :state_province, :country, :business_zip_code]
		    
		    CSV.foreach(params['csv'].tempfile, headers: true, skip_blanks: true, header_converters: :symbol, skip_lines: /^(?:[,:]\s*)+$/) do |row|
		      error = false
		      if !headers_checked
		      	headers_ary = row.map { |v| v[0] }
		      	raise StandardError, "Unable to proceed because the number of headers are incorrect." if headers.length != headers_ary.length
		      	raise StandardError, "Unable to proceed because the headers are incorrect." if headers.to_set != headers_ary.to_set
		      	headers_checked = true
		      	next
		      end
		      
		      row = row.to_hash
		      
		      # don't process the dummy data we put in the template file
		      unless row[:email] == '<redacted_email>'
		        error_message = "Unable to add customer with email: #{row[:email]} because"
					      		   		
			   		# Validate number
			      valid_num = TextingService.number_lookup(row[:phone_number])
			      if valid_num.present?
			      	row[:phone_number] = valid_num[0]
			      	if num_reach == 'domestic' && current_user.country != valid_num[1]
			      		response.push(error_message + " your rhombus number has only domestic reach.")
			      		error = true
			      	end
			      else
			      	response.push(error_message + " phone_number is invalid.")
			      	error = true
			      end

			      # set user_level and password
						row[:user_level] = 0
						row[:password] = 'temp_password'
						row[:referrer_num] = current_user.rhombus_number
						row[:country].present? && row[:country] = row[:country].upcase

						# validate user data against db
						if error
							user = User.new(row)
							user.valid?
						else 
							user = User.create(row)
						end
						
						# check for errors
						if user.errors.messages.present?
							user.errors.messages.each do |k,v|
								v.each do |r|
									response.push(error_message + " #{k} #{r}.")
								end
							end
						else
							# send email or text here
						end			   
					end
		    end

		    render json: { response: response }, status: 200
		  else
		  	render json: { response: 'Request is not supported.' }, status: 405
		  end
		rescue StandardError => e
			render json: { response: e.message }, status: 500
		end
  end


end