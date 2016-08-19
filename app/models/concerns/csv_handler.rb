module CSVHandler
  extend ActiveSupport::Concern

  def get_transactions_csv(user_id, user_level, start_date, end_date)
  	begin
	  	column_names = get_csv_columns(user_level)
	  	CSV.generate(headers: true) do |csv|
	      csv << column_names.map.with_index(0) { |e,i| (i == 0) ? e : e.titleize } 
	      column_names[0] = 'created_at'
		    Transaction.where("user_id = ? AND created_at BETWEEN ? AND ?", user_id, start_date, end_date).each do |t|
		      csv.add_row t.attributes.slice(*column_names).values
		    end
	    end
	  rescue StandardError => e
	  	false
	  end
	end

  def get_csv_columns(user_level)
  	return ["Date (ET)", "transaction_number", "from", "to", "amount", "amount_less_fees", "currency"] if user_level == 1
  	["Date (ET)", "transaction_number", "from", "to", "amount", "currency"]
  end

  def get_customer_csv_template
    attributes = ['first_name', 'last_name', 'email', 'phone_number', 'street_address', 'city', 'state_province', 'country', 'zip_code']
    default_text = ['John', 'Smith', '<redacted_email>', '<redacted_phone_number>', '2 Neverland Place', 'Boston', 'MA', 'US', '12345']
    CSV.generate(headers: true) do |csv|
      csv << attributes
      csv << default_text
    end
  end

  def upload_customer_csv(file, num_reach)
  	begin
      
      headers_checked = false
    	response = []
      headers = [:first_name, :last_name, :email, :phone_number, :street_address, :city, :state_province, :country, :zip_code]
      
      CSV.foreach(file, headers: true, skip_blanks: true, header_converters: :symbol, skip_lines: /^(?:[,:]\s*)+$/) do |row|
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
  	      	if num_reach == 'domestic' && self.country != valid_num[1]
  	      		response.push(error_message + " your rhombus number has only domestic reach.")
  	      		error = true
  	      	end
  	      else
  	      	response.push(error_message + " phone_number is invalid.")
  	      	error = true
  	      end

  	      # set user_level and password
  				row[:user_level] = 0
  				row[:password] = Toolbox::StringGen.generate_random_string(8)
  				row[:referrer_num] = self.rhombus_number
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
      response
    rescue StandardError => e
      return e.message
    end
  end


end