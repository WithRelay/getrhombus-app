class Transaction < ActiveRecord::Base

  #include Transactionable
  # scope :ordering, -> { order(:DESC) }

  has_one :message
  belongs_to :user, counter_cache: true

  def charge_customer_card(amount, user, rhombus_number, message) 
  	
    begin
    
    # find merchant with rhombus number
  	merchant = User.find_by(rhombus_number: rhombus_number)
  	tax_rate = (((merchant.tax_rate.to_f)/100) + 1)                     # apply tax, default is 0
  	amount_with_taxes = (amount * tax_rate).round(0)			
    rhombus_fee = (0.006 * amount_with_taxes).round(0)

    # Create the charge on Stripe's servers
    tkn = Stripe::Token.create(
          {:customer => user.customer_uri},
          merchant.stripe_access_token  # user's access token from the Stripe Connect flow
    )

    response = Stripe::Charge.create({
          :amount => amount_with_taxes, # in cents
          :currency => "usd",
          :card => tkn.id,
          :description => "Payment from #{user.email}. Card name: #{user.card_name}. Last four: #{user.last_four}.",
          :application_fee => rhombus_fee
        },
        merchant.stripe_access_token                    # merchants's access token from the Stripe Connect flow
    )

      amount_in_hundreds = sprintf("%.2f", amount.to_f/100) 

    rescue Stripe::CardError => e
      # Since it's a decline, Stripe::CardError will be caught
      body = e.json_body
      err  = body[:error]

      @message = Message.new
      @message.nexmo_send_text_message(18, rhombus_number, user.phone_number, 
            "Your payment of $#{amount_in_hundreds} to #{merchant.business_name} failed because: #{err[:message]}.")

      Notification.payment_failure_notification(err, user, merchant, message).deliver
      return "failed"
    rescue Stripe::StripeError => e
      body = e.json_body
      err  = body[:error]
      Notification.payment_failure_notification(err, user, merchant, message).deliver
      return "failed"
    rescue StandardError => e
      Notification.payment_failure_notification(e, user, merchant, message).deliver
      return "failed"
    else

      amount_with_taxes_in_hundreds = sprintf("%.2f", amount_with_taxes.to_f/100)
      # Else proceed to save data and notify customer via text and email (plus tax and merchant name)
      # return "#{response.uri}, #{response.transaction_number}, #{response.source.last_four}, #{response.on_behalf_of.customer_uri}"
      @message = Message.new
      if merchant.tax_rate == "0"
        @message.nexmo_send_text_message(11, rhombus_number, user.phone_number, 
              "A payment of $#{amount_in_hundreds} was sent to #{merchant.business_name}. Thanks! :)")
      else
        @message.nexmo_send_text_message(11, rhombus_number, user.phone_number, 
          "A payment of $#{amount_with_taxes_in_hundreds} including taxes set by #{merchant.business_name} was sent. Thanks! :)")
      end

        # save transaction
      self.save_transaction(transaction_uri: response.id, transaction_type: 1, 
          amount: amount_in_hundreds, transaction_number: response.id, 
          description: "Payment to #{merchant.email}. #{merchant.business_name}. rhombus number: #{rhombus_number}", 
          from: user.phone_number, to: merchant.rhombus_number, status: response.paid, 
          transaction_available_at: response.created, last_four: response.card.last4,
          expiration_month: response.card.exp_month, 
          expiration_year: response.card.exp_year, 
          card_type: response.card.type, card_name: response.card.name,
          tax_rate: merchant.tax_rate, on_behalf_of_uri: merchant.stripe_access_token,
          referenced_merchant_id: merchant.id, user_id: user.id, notes: message,
          amount_with_taxes: sprintf("%.2f", response.amount.to_f/100))
        
      # send receipt
      Notification.send_receipt(message, response.id, amount_with_taxes_in_hundreds, amount_in_hundreds, user.email, merchant.business_name, merchant.business_phone, merchant.email).deliver
      self.receipt_sent_at = Time.zone.now                       # change this later
      self.save                                                  # Put a save check here later
      # should limit data carried in merchant...memory
      return self.id, amount_in_hundreds, amount_with_taxes_in_hundreds, merchant, sprintf("%.2f", rhombus_fee.to_f/100), response.id
    end
  end
   
  def merchant_transaction_details(debit_data, user, message)
    # can find merchant if I pass rhombus number => User.find_by(rhombus_number: rhombus_number)
    merchant = debit_data[3]
    self.save_transaction(transaction_uri: debit_data[5], transaction_type: 2, amount: debit_data[1],
     amount_less_fees: debit_data[2].to_f - debit_data[4].to_f, 
        description: "Payment from #{user.email}. Card name: #{user.card_name}. Last four: #{user.last_four}.", 
        from: user.phone_number, to: merchant.rhombus_number, tax_rate: merchant.tax_rate,
        transaction_number: debit_data[5],
        # need to grab this info from balanced ?? #account_number: "", account_type: "", account_name: "", routing_number: ""
        referenced_user_id: user.id, referenced_customer_transaction_id: debit_data[0], last_four: user.last_four,
        user_id: merchant.id, notes: message, amount_with_taxes: debit_data[2])          
    return self.id                                              # Put a save check here later
  end

   def owner_transaction_details(debit_data, credit_data, user, message)  # merchant_transaction_id, user, message)
      
      #owner = User.find_by(email: '<redacted_email>')                        # for development
      owner = User.find_by(email: '<redacted_email>')                        # test production
      #owner = User.find_by(email: '<redacted_email>')                # for production

      # or db query to retreive data rather than passing it
      # merchant_id = Transaction.find_by(id: merchant_transaction_id).user_id
      # User.find_by(id: merchant_id)
      merchant = debit_data[3]      
      self.save_transaction(transaction_uri: debit_data[5], transaction_type: 0,
        amount: debit_data[4], amount_less_fees: debit_data[2].to_f - debit_data[4].to_f, transaction_number: debit_data[5],
        description: "Payment from #{user.email}. Name on card: #{user.card_name}. Last four: #{user.last_four} to #{merchant.email}", 
        from: user.phone_number, to: merchant.rhombus_number, tax_rate: merchant.tax_rate, last_four: user.last_four,
        referenced_user_id: user.id, referenced_customer_transaction_id: debit_data[0], user_id: owner.id, notes: message, 
        amount_with_taxes: debit_data[2], referenced_merchant_transaction_id: credit_data[0], 
        referenced_merchant_id: merchant.id)                                         # Put a save check here later
    end


   def save_transaction(options = {})

     #   debugger
   		
   		  self.transaction_uri = options[:transaction_uri] if options[:transaction_uri]
      	self.transaction_type = options[:transaction_type] if options[:transaction_type]
      	self.amount = options[:amount] if options[:amount]
      	self.amount_less_fees = options[:amount_less_fees] if options[:amount_less_fees]
      	self.transaction_number = options[:transaction_number] if options[:transaction_number]
      	
      	self.description = options[:description] if options[:description]
      	self.from = options[:from] if options[:from]
      	self.to = options[:to] if options[:to]
      	self.status = options[:status] if options[:status]
      	self.transaction_available_at = options[:transaction_available_at] if options[:transaction_available_at]
      	
      	self.last_four = options[:last_four] if options[:last_four]
      	self.expiration_month = options[:expiration_month] if options[:expiration_month]
      	self.expiration_year = options[:expiration_year] if options[:expiration_year]
      	#self.zip_code = options[:zip_code] if options[:zip_code]
      	self.card_type = options[:card_type] if options[:card_type]
      	self.card_name	= options[:card_name] if options[:card_name]
      	
      	self.tax_rate = options[:tax_rate] if options[:tax_rate]
      	self.on_behalf_of_uri = options[:on_behalf_of_uri] if options[:on_behalf_of_uri]
      	#self.account_number = options[:account_number] if options[:account_number]
      	#self.account_type = options[:account_type] if options[:account_type]
      	#self.account_name = options[:account_name] if options[:account_name]
      	#self.routing_number = options[:routing_number] if options[:routing_number]

      	self.referenced_user_id = options[:referenced_user_id] if options[:referenced_user_id]
      	self.referenced_customer_transaction_id = options[:referenced_customer_transaction_id] if options[:referenced_customer_transaction_id]
		   	self.user_id = options[:user_id] if options[:user_id]
      	self.notes = options[:notes] if options[:notes]
      	self.amount_with_taxes = options[:amount_with_taxes] if options[:amount_with_taxes]
      	self.referenced_merchant_transaction_id = options[:referenced_merchant_transaction_id] if options[:referenced_merchant_transaction_id]
      	self.referenced_merchant_id = options[:referenced_merchant_id] if options[:referenced_merchant_id]

        #self.refund_reason = options[:refund_reason] if options[:refund_reason]

      	self.save 										# add a check here later
   end
end

