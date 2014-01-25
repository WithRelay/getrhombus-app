class Transaction < ActiveRecord::Base

	Balanced.configure('cb51061889c511e2ac81026ba7cd33d0') 

   	has_one :message
   	belongs_to :user, counter_cache: true

   	rhombus_fee = 0.02				# :)

	
   	def balanced_debit_customer_card(amount, user, rhombus_number, message)
   	  	#payee_uri = "/v1/customers/CU1UTgvrRR6pVLksnVpv4l6T"     # will throw insufficient fund
      	#merchant_uri = "/v1/customers/CU20htXmtjNsleBvmhwai9sP"
      	#user.id = "12"

      	# find merchant with rhombus number
      	merchant = User.find_by(rhombus_number: rhombus_number)
      
      	# apply tax, default is 0
      	tax_rate = (((merchant.tax_rate.to_f)/100) + 1)
      	amount_with_taxes = (amount * tax_rate).round(0)					

      	customer = Balanced::Customer.find(user.customer_uri)            		# Add a check here later
      	begin

   	   		response = customer.debit(:amount => amount_with_taxes,
                :on_behalf_of_uri => merchant.customer_uri, :appears_on_statement_as => merchant.business_name,
                :description => "Payment from #{user.email} to #{merchant.email}. Business name: #{merchant_business_name}. rhombus number: #{rhombus_number}")

      	rescue Exception => e        
        	# Handle bad response
         	failure_reason = e.response[:body]["category_code"]
         	status_code = e.response[:body]["status_code"]

         	# Notify customer on failed debit
        	message = Message.new
         	if amount > 100 and status_code == 402                   			# How about 409???
            	message.nexmo_send_text_message(<redacted_phone_number>, <redacted_phone_number>, 
            		"Your payment of #{amount/100} dollars to #{merchant_name} failed because: #{failure_reason}.")
         	elsif amount < 100 and status_code == 402
            	message.nexmo_send_text_message(<redacted_phone_number>, <redacted_phone_number>, 
              		"Your payment of #{amount} cents to #{merchant_name} failed because: #{failure_reason}.")
         	elsif amount == 100 and status_code == 402
            	message.nexmo_send_text_message(<redacted_phone_number>, <redacted_phone_number>, 
              		"Your payment of #{amount/100} dollar to #{merchant_name} failed because: #{failure_reason}.")
         	end

         	# Notify marketplace owner of failed debit
         	# return e.response[:body], failure_reason, status_code, e.response[:body]["description"]
         	Notification.payment_failure_notification(e.response[:body]).deliver

      	else

         	# Else proceed to save data and notify customer via text and email (plus tax and merchant name)
         	# return "#{response.uri}, #{response.transaction_number}, #{response.source.last_four}, #{response.on_behalf_of.customer_uri}"
            @message = Message.new
            if merchant.tax_rate != "0"
            	@message.nexmo_send_text_message(rhombus_number, user.phone_number, 
            		"A payment of #{amount/100} dollars was sent to #{merchant_business_name}. Thanks! :)")
            else
            	@message.nexmo_send_text_message(rhombus_number, user.phone_number, 
            		"A payment of #{amount_with_taxes/100} dollars including taxes set by #{merchant_business_name} was sent. Thanks! :)")
            end

            # save transaction
      		self.save_transaction(transaction_uri: response.uri, transaction_type: 1, amount: response.amount/100, 
      			transaction_number: response.transaction_number, description: response.description, from: user.phone_number, 
      			to: merchant.rhombus_number, status: response.status, transaction_available_at: response.available_at, 
      			last_four: response.customer.last_four, expiration_month: response.source.expiration_month, 
      			expiration_year: response.source.expiration_year, zip_code: response.source.postal_code, card_type: response.source.card_type, 
      			card_name: response.source.card_name, appears_on_statement_as: response.appears_on_statement_as, tax_rate: merchant.tax_rate,
				on_behalf_of_uri: response.on_behalf_of.customer_uri, referenced_merchant_id: merchant.id, user_id: user.id,
				notes: message, amount_with_taxes: response.amount_with_taxes/100)
      		# send receipt
      		Notification.send_receipt(response, tax_rate, merchant.business_name).deliver
      		self.receipt_sent_at = Time.now							# change this later
      		self.save												# Put a save check here later
      		return self.id, amount, amount_with_taxes
      	end
   end



   def balanced_credit_merchant_bank_account(debit_data, user, rhombus_number, message)
   		#merchant_uri = '/v1/customers/CU20htXmtjNsleBvmhwai9sP'
  	   	
  	   	# find merchant with rhombus number
      	merchant = User.find_by(rhombus_number: rhombus_number)
      	amount_less_fees = (debit_data[1] * (1 - rhombus_fee)).round(0)
      	fee = (debit_data[1] * rhombus_fee).round(0)
      	amount = debit_data[2] - fee						# what the merchant gets

   		customer = Balanced::Customer.find(merchant.customer_uri)           # Add a check here later
      	begin
    		
    		response = customer.credit(:amount => amount,
            	:description => "Payment from #{user.email}. Name on card: #{user.card_name}. Last four: #{user.last_four}.",
            	:appears_on_statement_as => "#{user.card_name}_#{user.last_four}")

      	rescue Exception => e
        	
        	# Handle bad response, Notify merchant and marketplace owner of failure
        	#return e, e.response[:body]["category_code"], e.response[:body]["status_code"], e.response[:body]["description"]
         	Notification.payment_failure_notification(e.response[:body], merchant.email).deliver
         	
      	else
        	# Else proceed to save data, return id
         	#return "#{response.uri}, #{response.transaction_number}, #{response.source.last_four}, #{response.on_behalf_of.customer_uri}"
        	transaction_id = self.save_transaction(transaction_uri: response.uri, transaction_type: 2, amount: (response.amount)/100, 
        		amount_less_fees: amount_less_fees/100, transaction_number: response.transaction_number, description: response.description, 
        		from: user.phone_number, to: merchant.rhombus_number, status: response.status, transaction_available_at: response.available_at,
        		appears_on_statement_as: response.appears_on_statement_as, tax_rate: merchant.tax_rate,
        		account_number: response.destination.account_number, account_type: response.destination.type,
        		account_name: response.destination.name, routing_number: response.destination.routing_number, referenced_user_id: user.id, 
        		referenced_customer_transaction_id: debit_data[0], user_id: merchant.id,	notes: message, amount_with_taxes: debit_data[2]/100)
        	return transaction_id			
      	end
   end



   def balanced_payout_to_marketplace_bank_account(debit_data, merchant_transaction_id, user, message)
      
      	owner = User.find_by(phone_number: from)
      	merchant_id = Transaction.find_by(id: merchant_transaction_id).user_id
      	merchant = User.find_by(id: merchant_id)

      	# debit amount (less tax) times fee
      	fee = (debit_data[1] * rhombus_fee).round(0)
      	amount_less_fees = debit_data[0] - fee
      	marketplace = Balanced::Marketplace.mine                           # Add a check here later

      	begin
   	   		response = marketplace.owner_customer.credit(:amount => fee, 
            	:description => "Payment from #{user.email}. Name on card: #{user.card_name}. Last four: #{user.last_four}".,
            	:appears_on_statement_as => "#{user.card_name}_#{user.last_four}")
   		rescue Exception => e
        	# Handle bad response and Notify marketplace owner of failed credit
        	#return e.response[:body]["category_code"], e.response[:body]["status"], e.response[:body]["status_code"], e.response[:body]["description"]
        	Notification.payment_failure_notification(e.response[:body]).deliver
     	else
        	# Else process to save data #also returns credit_uri so save it
        	#return "#{response.uri}, #{response.status}" 
        	self.save_transaction(transaction_uri: response.uri, transaction_type: 2, amount: (response.amount)/100, 
        		amount_less_fees: amount_less_fees/100, transaction_number: response.transaction_number, 
        		description: response.description, from: user.phone_number, to: merchant.rhombus_number, status: response.status, 
        		transaction_available_at: response.available_at, appears_on_statement_as: response.appears_on_statement_as, 
        		tax_rate: merchant.tax_rate, account_number: response.destination.account_number, account_type: response.destination.type, 
        		account_name: response.destination.name, routing_number: response.destination.routing_number, 
        		referenced_user_id: user.id, referenced_customer_transaction_id: debit_data[0], user_id: owner.id, 
        		notes: message, amount_with_taxes: debit_data[2]/100, referenced_merchant_transaction_id: merchant_transaction_id,
        		referenced_merchant_id: merchant_id)
      	end
   	end

   def save_transaction(options = {})
   		
   		self.transaction_uri = options[:transaction_uri] if options[:transaction_uri]
      	self.transaction_type = options[:transaction_type] if options[:transaction_type]
      	self.amount = options[:amount] if options[:amount]
      	self.amount_less_fees = options[:amount_less_fees] if options[:amount_less_fees]
      	self.transaction_number = options[:transaction_number] if options[:transaction_number]
      	
      	self.description = options[:description] if options[:description]
      	self.from = options[:phone_number] if options[:phone_number]
      	self.to = options[:rhombus_number] if options[:rhombus_number]
      	self.status = options[:status] if options[:status]
      	self.transaction_available_at = options[:transaction_available_at] if options[:transaction_available_at]
      	
      	self.last_four = options[:last_four] if options[:last_four]
      	self.expiration_month = options[:expiration_month] if options[:expiration_month]
      	self.expiration_year = options[:expiration_year] if options[:expiration_year]
      	self.zip_code = options[:zip_code] if options[:zip_code]
      	self.card_type = options[:card_type] if options[:card_type]
      	self.card_name	= options[:card_name] if options[:card_name]
      	self.appears_on_statement_as = options[:appears_on_statement_as] if options[:appears_on_statement_as]
      	
      	self.tax_rate = options[:tax_rate] if options[:tax_rate]
      	self.on_behalf_of_uri = options[:on_behalf_of_uri] if options[:on_behalf_of_uri]
      	self.account_number = options[:account_number] if options[:account_number]
      	self.account_type = options[:account_type] if options[:account_type]
      	self.account_name = options[:account_name] if options[:account_name]
      	self.routing_number = options[:routing_number] if options[:routing_number]

      	self.referenced_user_id = options[:referenced_user_id] if options[:referenced_user_id]
      	self.referenced_customer_transaction_id = options[:referenced_customer_transaction_id] if options[:referenced_customer_transaction_id]
		self.refund_reason = options[:refund_reason] if options[:refund_reason]
      	self.user_id = options[:user_id] if options[:user_id]
      	self.notes = options[:notes] if options[:notes]
      	self.amount_with_taxes = options[:amount_with_taxes] if options[:amount_with_taxes]
      	self.referenced_merchant_transaction_id = options[:referenced_merchant_transaction_id] if options[:referenced_merchant_transaction_id]
      	self.referenced_merchant_id = options[:referenced_merchant_id] if options[:referenced_merchant_id]

      	self.save 										# add a check here later

      	return self.id
   end

end

=begin
	   # For refunds
   def balanced_debit_merchant_and_marketplace_bank_accounts               
      customer_last_name = "Duvall"
      customer_last_four = "3212"
      refund_reason = "not happy with product"
      transaction_number = "<redacted_phone_number>"  
      #####################

      merchant_credit_uri = '/v1/customers/CU20htXmtjNsleBvmhwai9sP/credits/CR611BegVtooirWHJCzRpLDp'
      # Reverse credit to merchant
      credit = Balanced::Credit.find(merchant_credit_uri)                  # Add a check here later
      begin
         response = credit.reverse(:description => "#{customer_last_name}_#{customer_last_four} refund")  
      rescue Exception => e
         # Handle bad response
         return e.response[:body]["category_code"], e.response[:body]["status"], 
               e.response[:body]["status_code"], e.response[:body]["description"]
         # Notify merchant and marketplace owner of failed credit
      else
         # Else process to save data #also returns reversal uri
         #response.to_yaml
         #return "#{response.uri}, #{response.transaction_number}"
      end

      marketplace_credit_uri = '/v1/customers/AC6bPlDatNUQbfeUNPH11jAY/credits/CR3iJQMrltqQVQeS3Ew8qscu'
      # Reverse credit to marketplace account
      credit = Balanced::Credit.find(marketplace_credit_uri)               # Add a check here later
      begin
         response = credit.reverse(:description => "#{customer_last_name}_#{customer_last_four}_#{transaction_number} refund: #{refund_reason}")
      rescue Exception => e
         # Handle bad response
         return e.response[:body]["category_code"], e.response[:body]["status"], 
               e.response[:body]["status_code"], e.response[:body]["description"]
         # Notify marketplace owner of failed credit
      else
         # Else process to save data #also returns reversal uri
         #response.to_yaml
         #return "#{response.uri}, #{response.transaction_number}"
      end
   end


   def balanced_issue_refund_to_customer   
      ###### Return Find user-transaction debit uri
      debit_uri = '/v1/marketplaces/TEST-MP6bP0y8O10lBsBfh8oMGhE4/debits/WD49dpZZTxnod04atFKYHQpF'
      merchant_name = "Chris Tello"
      transaction_number = "<redacted_phone_number>"
      customer_last_name = "Paul Jones"
      customer_last_four = "2222"
      refund_reason = "not happy with product"
      #################

      # Issue refund to customer prior debit
      debit = Balanced::Debit.find(debit_uri)                    # Add a check here later
      begin
         response = debit.refund(:description => "#{customer_last_name}_#{customer_last_four}_#{transaction_number} refund: #{refund_reason}")
      rescue Exception => e
         # Handle bad response
         return e.response[:body]["category_code"], e.response[:body]["status"], 
                 e.response[:body]["status_code"], e.response[:body]["description"]
         # Notify marketplace owner of failed credit
      else
         # Else process to save data # already set by default === response.appears_on_statement_as
         return "#{response.uri}" 
      end
   end
	
=end
