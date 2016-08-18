module MakeSpreadsheet
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


end