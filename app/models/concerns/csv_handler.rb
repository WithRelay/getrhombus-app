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
          Transaction.where(column_str + " = ? AND created_at >= ? AND created_at < ?", user_id, Time.zone.parse(start_date), Time.zone.parse(end_date) + 1.days)
            .where.not(subscription_id: nil)
        else
          Transaction.exclude_refunded_transactions().where(column_str + " = ? AND transactions.created_at >= ? AND transactions.created_at < ?", user_id, Time.zone.parse(start_date), Time.zone.parse(end_date) + 1.days)
            .only_captured_transactions().exclude_subscriptions()
        end
        transactions.each do |t|
          csv << column_names.map{ |attr| t.send(attr) }
        end
      end
    rescue StandardError => e
      ExceptionNotifier.notify_exception(e, data: { message: "In get_transactions_csv", env: Rails.env, user_id: user_id, start_date: start_date, end_date: end_date, subscription: subscription })
      false
    end
  end

  def get_csv_columns(is_merchant)
    return ["Date (#{Time.current.zone})", "transaction_number", "customer_email", "txn_amount", "txn_amount_less_fees", "card_name", "last4", "notes", "currency"] if is_merchant
    ["Date #{Time.current.zone}", "transaction_number", "business_email", "business_org_name", "txn_amount", "card_name", "last4", "notes", "currency"]
  end

  def get_customer_csv_template
    attributes = ['first_name', 'last_name', 'email', 'phone_number', 'street_address', 'city', 'state_province', 'country', 'postal_code']
    default_text = ['John', 'Smith', '<redacted_email>', '<redacted_phone_number>', '2 Neverland Place', 'Boston', 'MA', 'US', '12345']
    CSV.generate(headers: true) do |csv|
      csv << attributes
      csv << default_text
    end
  end

  def get_contact_csv_template
    attributes = ['phone_number']
    default_text = ['<redacted_phone_number>', '<redacted_phone_number>']
    CSV.generate(headers: true) do |csv|
      csv << attributes
      csv << [default_text.first]
      csv << [default_text.second]
    end
  end

  # https://andrew.coffee/blog/skipping-blank-lines-in-ruby-csv-parsing.html
  # http://technicalpickles.com/posts/parsing-csv-with-ruby/
  def upload_customer_csv(file_path)
    begin
      response, headers_checked, error_hash = [], false, {}

      CSV::Converters[:blank_to_nil] = lambda do |field|
        field && field.blank? ? nil : field
      end

      headers = [:first_name, :last_name, :email, :phone_number, :street_address, :city, :state_province, :country, :postal_code]
      file_data = CSV.read(file_path, headers: true, skip_blanks: true, header_converters: :symbol, converters: [:all, :blank_to_nil], skip_lines: /^(?:[,:;]\s*)+$/)
      file_headers = file_data.headers

      file_data.each do |row|
        error = false

        # Validate headers
        if !headers_checked
          if headers.length != file_headers.length
            response.push(['The File Headers', ["Unable to proceed because the number of headers are incorrect."]])
            break
          end

          if headers.to_set != file_headers.to_set
            response.push(["The File Headers", ["Unable to proceed because the headers are incorrect."]])
            break
          end

          headers_checked = true
        end

        row = row.to_hash
        @customer = User.find_by(email: row[:email])

        if @customer.blank?
          # don't process the dummy data we put in the template file
          if row[:email].present? && row[:email] != '<redacted_email>'
            error_hash[row[:email]] = []

            begin
              # Validate number
              valid_num = TextingService.number_lookup(row[:phone_number].to_s.gsub(/\D/, ''))
              if valid_num.present?
                row[:phone_number] = valid_num.first
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
                  @customer = User.new(email: row[:email], password: row[:password], phone_number: row[:phone_number], user_level: row[:user_level])
                  @customer.customer_source = { id: self.id, method: 'added', temp_password: row[:password] }
                  @customer.save!

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
                  v.each { |r| error_hash[row[:email]].push("#{k}".humanize + " #{r}.") }
                end
                error = true
              else
                MerchantCustomer.add_or_update_merchant_customer(User.get_platform_acct_obj, @customer)
                MerchantCustomer.add_or_update_merchant_customer(self, @customer)
                Referrer.save_referrer_with_uid(self.relay_uid, @customer.id)
              end
            rescue ActiveRecord::RecordNotUnique => e
              ExceptionNotifier.notify_exception(e, data: { message: "In upload_customer_csv first exception block", env: Rails.env, self: self })
              msg = e.original_exception.message
              error_hash[row[:email]].push("Phone number is already in use.") if msg.include?('index_users_on_phone_number')
              error_hash[row[:email]].push("Email is already in use.") if msg.include?('index_users_on_email')
              error = true
            rescue StandardError => e
              ExceptionNotifier.notify_exception(e, data: { message: "In upload_customer_csv second exception block", env: Rails.env, self: self })
              error = true
              error_hash[row[:email]].push("Something went wrong on our end.")
            end

            error_hash.delete(row[:email]) unless error
          end
        else
          MerchantCustomer.add_or_update_merchant_customer(self, @customer) if @customer.is_customer?
        end
      end

      # change hash to array
      error_hash.each do |key, value|
        ary = []
        value.each { |v| ary.push(v) }          
        response.push([key, ary])  
      end
      puts 'are there any errors?'
      puts response.inspect
      response
    rescue StandardError => e
      ExceptionNotifier.notify_exception(e, data: { message: "In upload_customer_csv third exception block", env: Rails.env, self: self })
      ['File Upload', ["Something went wrong on our end."]]
    end
  end

#=begin
  def upload_contact_csv(file_path)
    begin
      response, headers_checked, error_hash = [], false, {}

      CSV::Converters[:blank_to_nil] = lambda do |field|
        field && field.blank? ? nil : field.to_s.squish
      end

      #headers = [:phone_number]
      # for brian
      headers = [:phone_number, :first_name, :last_name, :organization, :email]
      file_data = CSV.read(file_path, headers: true, skip_blanks: true, header_converters: :symbol, converters: [:all, :blank_to_nil], skip_lines: /^(?:[,:;]\s*)+$/)
      file_headers = file_data.headers

      # for brian
      list = self.lists.create({ name: 'Lead List', channel: 0, origin: 0, list_type: 1, campaign_type: 0 }) unless List.exists?(user_id: self.id, name: 'Lead List')

      file_data.each do |row|
        error = false

        # Validate headers
        if !headers_checked
          if headers.length != file_headers.length
            response.push(['The File Headers', ["Unable to proceed because the number of headers are incorrect."]])
            break
          end

          if headers.to_set != file_headers.to_set
            response.push(["The File Headers", ["Unable to proceed because the headers are incorrect."]])
            break
          end

          headers_checked = true
        end

        row = row.to_hash        
        valid_num = TextingService.number_lookup(row[:phone_number].to_s.gsub(/\D/, ''), true)
        
        row[:phone_number] = valid_num.first if valid_num.present?
        error_hash[row[:phone_number]] = []


        if valid_num.present?
          if valid_num.fourth == "mobile"
            # check if a customer type user already has this number
            @customer = User.find_by(phone_number: row[:phone_number])
            
            if @customer.blank?
              begin            
                MerchantContact.add_or_update_merchant_contact(User.get_platform_acct_obj.id, row[:phone_number], 'phone_number'.freeze)
                #MerchantContact.add_or_update_merchant_contact(self.id, row[:phone_number], 'phone_number'.freeze)                
                #OpenCnamData.find_record_or_get_intelligence_data(row[:phone_number])

                # for brian
                mc = MerchantContact.add_or_update_merchant_contact(self.id, row[:phone_number], 'phone_number'.freeze)                
                list.user_lists.create!(customer_contact_id: mc.id, customer_contact_type: "MerchantContact") if mc
                MerchantContact.where(uid: row[:phone_number]).update_all(email: row[:email].try(:downcase), first_name: row[:first_name], last_name: row[:last_name], organization: row[:organization])
                
              rescue StandardError => e
                error = true
                ExceptionNotifier.notify_exception(e, data: { message: "In upload_contact_csv first exception block", env: Rails.env, self: self })
                error_hash[row[:phone_number]].push("Something went wrong on our end.")
              end

              error_hash.delete(row[:phone_number]) unless error
            else
              MerchantCustomer.add_or_update_merchant_customer(User.get_platform_acct_obj, @customer)
              MerchantCustomer.add_or_update_merchant_customer(self, @customer)
            end
          else
            error_hash[row[:phone_number]].push('Phone number is not a mobile number.')
          end
        else
          error_hash[row[:phone_number]].push('Phone number is invalid.')
        end
      end

      # change hash to array
      error_hash.each do |key, value|
        ary = []
        value.each { |v| ary.push(v) }          
        response.push([key, ary])  
      end

      EmailingService.csv_upload_failure(response)
      puts 'are there any errors?'
      puts response.inspect
      response
    rescue StandardError => e
      ExceptionNotifier.notify_exception(e, data: { message: "In upload_contact_csv second exception block", env: Rails.env, self: self })
      ['File Upload', ["Something went wrong on our end."]]
    end
  end
#=end 

=begin
  def upload_contact_csv(file_path)
    begin  
      merchant = User.find 712

#=begin
      merchant.lists.create([
        { name: 'Facebook Leads', channel: 0, origin: 0, list_type: 1, campaign_type: 0 },
        { name: 'Hang up on Machine', channel: 0, origin: 0, list_type: 1, campaign_type: 0 },
        { name: 'Live Answer No Survey', channel: 0, origin: 0, list_type: 1, campaign_type: 0 },
        { name: 'Live Answer With Survey', channel: 0, origin: 0, list_type: 1, campaign_type: 0 },
        { name: 'NoAnswer', channel: 0, origin: 0, list_type: 1, campaign_type: 0 },
      ])
#=end
  
      CSV::Converters[:blank_to_nil] = lambda do |field|
        field && field.blank? ? nil : field
      end

      file_data = CSV.read(file_path, headers: true, skip_blanks: true, header_converters: :symbol, converters: [:all, :blank_to_nil], skip_lines: /^(?:[,:;]\s*)+$/)

      file_data.each do |row|
        row = row.to_hash          
        row[:phone_number] = row[:phone_number].to_s.squish
        row[:seg] = row[:seg].to_s.squish
        
        # check if a customer type user already has this number
        customer = User.find_by(phone_number: row[:phone_number])    
        
        if customer.blank?
          mc = MerchantContact.find_by(merchant_id: 712, uid: row[:phone_number])    
          if mc
            list = List.find_by(user_id: 712, name: row[:seg])
            list.user_lists.create!(customer_contact_id: mc.id, customer_contact_type: "MerchantContact")
          end   
        end

      end
    rescue StandardError => e
      ExceptionNotifier.notify_exception(e, data: { message: "In upload_contact_csv second exception block", env: Rails.env, self: self })
      ['File Upload', ["Something went wrong on our end."]]
    end
  end
=end

end