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
          Transaction.where(column_str + " = ? AND created_at BETWEEN ? AND ?", user_id, Time.zone.parse(start_date), Time.zone.parse(end_date))
            .where.not(subscription_id: nil)
        else
          Transaction.exclude_refunded_transactions().where(column_str + " = ? AND transactions.created_at BETWEEN ? AND ?", user_id, Time.zone.parse(start_date), Time.zone.parse(end_date))
            .only_captured_transactions().exclude_subscriptions()
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
    return ["Date (#{Time.current.zone})", "transaction_number", "customer_email", "txn_amount", "txn_amount_less_fees", "card_name", "last4", "notes", "currency"] if is_merchant
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

  # https://andrew.coffee/blog/skipping-blank-lines-in-ruby-csv-parsing.html
  # http://technicalpickles.com/posts/parsing-csv-with-ruby/
  def upload_customer_csv(file)
    begin
      response = []
      headers_checked = false
      error_hash = {}
      headers = [:first_name, :last_name, :email, :phone_number, :street_address, :city, :state_province, :country, :postal_code]

      CSV::Converters[:blank_to_nil] = lambda do |field|
        field && field.blank? ? nil : field
      end

      CSV.foreach(file, headers: true, skip_blanks: true, header_converters: :symbol, converters: [:all, :blank_to_nil], skip_lines: /^(?:[,:;]\s*)+$/) do |row|

        error = false

        # Validate headers
        if !headers_checked
          headers_ary = row.map { |v| v[0] }
          if headers.length != headers_ary.length
            response.push(['The File Headers', ["Unable to proceed because the number of headers are incorrect."]])
            break
          end

          if headers.to_set != headers_ary.to_set
            response.push(["The File Headers", ["Unable to proceed because the headers are incorrect."]])
            break
          end

          headers_checked = true
          next
        end

        row = row.to_hash
        @customer = User.where(email: row[:email])

        if @customer.blank?
          # don't process the dummy data we put in the template file
          unless row[:email] == '<redacted_email>' && row[:email].blank?
            error_hash[row[:email]] = []

            begin
              # Validate number
              valid_num = TextingService.number_lookup(row[:phone_number])
              if valid_num.present?
                row[:phone_number] = valid_num[0]
              else
                error_hash[row[:email]].push('Phone number is invalid.')
                error = true
              end

              # Validate email
              unless EmailValidatorService.verify_email(row[:email])
                error_hash[row[:email]].push('Email is invalid.')
                error = true
              end

              # set user_level and password
              row[:user_level] = 0
              row[:password] = Toolbox::StringGen.generate_random_string(8)

              # validate user data against db
              if error
                @customer = User.new(email: row[:email], password: row[:password], phone_number: row[:phone_number], user_level: row[:user_level])
                @customer.valid?
              else
                ActiveRecord::Base.transaction do
                  @customer = User.create(email: row[:email], password: row[:password], phone_number: row[:phone_number], user_level: row[:user_level])
                  if @customer.persisted? && (row[:first_name] || row[:last_name])
                    person = @customer.people.create(first_name: row[:first_name], last_name: row[:last_name]) 
                    if person.persisted? && (row[:street_address] || row[:city] || row[:postal_code] || row[:state_province] || row[:country])
                      person.create_address(street_address: row[:street_address], city: row[:city], postal_code: row[:postal_code], 
                                             state_province: row[:state_province], country: row[:country])
                    end
                  end
                end
              end

              # check for @customer errors
              if @customer.errors.messages.present? || error
                @customer.errors.messages.each do |k,v|
                  v.each { |r| error_hash[row[:email]].push("#{k}.humanize.downcase #{r}.") }
                end
                error = true
              else
                MerchantCustomer.add_or_update_merchant_customer(self.id, @customer)
                Referrer.save_referrer_with_uid(self.relay_uid, @customer.id)
                # send email or text here
              end
            rescue ActiveRecord::RecordNotUnique => e
              msg = e.original_exception.message
              error_hash[row[:email]].push("Phone number is already in use.") if msg.include?('index_users_on_phone_number')
              error_hash[row[:email]].push("Email is already in use.") if msg.include?('index_users_on_email')
              error = true
            rescue StandardError => e
              error = true
              error_hash[row[:email]].push("Something went wrong on our end.")
            end

            error_hash.delete(row[:email]) unless error
          end
        else
          # send text here
          MerchantCustomer.add_or_update_merchant_customer(self.id, @customer)
        end
      end

      # change hash to array
      error_hash.each do |key, value|
        ary = []
        value.each { |v| ary.push(v) }          
        response.push([key, ary])  
      end
      response
    rescue StandardError => e
      # email platform
      ['File Upload', ["Something went wrong on our end."]]
    end
  end


end