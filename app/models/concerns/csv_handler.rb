module CSVHandler
  extend ActiveSupport::Concern

  def get_transactions_csv(user_id, is_merchant, start_date, end_date, subscription = false)
    begin
      column_str = is_merchant ? 'team_id' : 'user_id'
      column_names = get_csv_columns(is_merchant)
      CSV.generate(headers: true) do |csv|
        csv << column_names.map.with_index(0) { |e,i| (i == 0) ? e : e.titleize }
        column_names[0] = 'created_at'
        column_names[1] = 'txn_number'
        transactions = if subscription
          Transaction.where(column_str + " = ? AND created_at BETWEEN ? AND ?", user_id, Time.zone.parse(start_date), Time.zone.parse(end_date)).where.not(subscription_id: nil)
        else
          Transaction.where(column_str + " = ? AND created_at BETWEEN ? AND ?", user_id, Time.zone.parse(start_date), Time.zone.parse(end_date))
        end
        transactions.each do |t|
          csv << column_names.map{ |attr| t.send(attr) }
        end
      end
    rescue StandardError => e
      false
    end
  end

  def get_csv_columns(is_merchant)
    return ["Date #{Time.current.zone}", "transaction_number", "customer_email", "txn_amount", "txn_amount_less_fees", "card_name", "last4", "notes", "currency"] if is_merchant
    ["Date #{Time.current.zone}", "transaction_number", "business_email", "business_name", "txn_amount", "card_name", "last4", "notes", "currency"]
  end

  def get_customer_csv_template
    attributes = ['first_name', 'last_name', 'email', 'phone_number', 'street_address', 'city', 'state_province', 'country', 'postal_code']
    default_text = ['John', 'Smith', '<redacted_email>', '<redacted_phone_number>', '2 Neverland Place', 'Boston', 'MA', 'US', '12345']
    CSV.generate(headers: true) do |csv|
      csv << attributes
      csv << default_text
    end
  end

  def upload_customer_csv(file)
    begin

      headers_checked = false
      response = []
      headers = [:first_name, :last_name, :email, :phone_number, :street_address, :city, :state_province, :country, :postal_code]

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
        user = User.where(email: row[:email])

        if user.blank?
          # don't process the dummy data we put in the template file
          unless row[:email] == '<redacted_email>'
            error_message = "Unable to add customer with email: #{row[:email]} because"

            # Validate number
            valid_num = TextingService.number_lookup(row[:phone_number])
            if valid_num.present?
              row[:phone_number] = valid_num[0]
            else
              response.push(error_message + " phone_number is invalid.")
              error = true
            end

            # Validate email
            if !EmailValidatorService.verify_email(row[:email])
              response.push(error_message + " email is invalid.")
              error = true
            end

            # set user_level and password
            row[:user_level] = 0
            row[:password] = Toolbox::StringGen.generate_random_string(8)

            # validate user data against db
            if error
              user = User.new(row)
              user.valid?
            else
              ActiveRecord::Base.transaction do
                user = User.create(email: row[:email], password: row[:password], phone_number: row[:phone_number], user_level: row[:user_level])
                person = Person.create(first_name: row[:first_name], last_name: row[:last_name])
                user.persons = person
                person.address = Address.create(street_address: row[:street_address], city: row[:city],
                                  postal_code: row[:postal_code], state_province: row[:state_province], country: row[:country])
              end
            end

            # check for user errors
            if user.errors.messages.present? || error
              user.errors.messages.each do |k,v|
                v.each do |r|
                  response.push(error_message + " #{k} #{r}.")
                end
              end
            else
              ref = Referrer.where(referrer_id: self.id, referee_id: user.id).first_or_initialize
              ref.save
              # send email or text here
            end
          end
        else
          # send text here
        end
      end
      response
    rescue StandardError => e
      e.message
    end
  end


end