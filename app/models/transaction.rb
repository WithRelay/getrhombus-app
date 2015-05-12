class Transaction < ActiveRecord::Base

  include Transactionable
  # scope :ordering, -> { order(:DESC) }

  has_one :message
  belongs_to :user, counter_cache: true

  def charge_customer_card(amount, merchant, user, message) 
  	
    begin
    
    	tax_rate = (((merchant.tax_rate.to_f)/100) + 1)                     # apply tax, default is 0
    	amount_with_taxes = (amount.to_f * tax_rate).round(0)			
      rhombus_fee = 0                                                     #(0.006 * amount_with_taxes.to_f).round(0)

      # Create the charge on Stripe's servers
      tkn = Stripe::Token.create(
            {:customer => user.customer_uri},
            merchant.stripe_access_token  # user's access token from the Stripe Connect flow
      )

      response = Stripe::Charge.create({
            :amount => amount_with_taxes, # in cents
            :currency => "usd",
            :card => tkn.id,
            #:application_fee => rhombus_fee
            :description => "Payment from #{user.email}. Card name: #{user.card_name}. Last four: #{user.last_four}.",
            :metadata => {
              "message" => message
            }            
          },
          merchant.stripe_access_token                    # merchants's access token from the Stripe Connect flow
      )

      amount_in_hundreds = sprintf("%.2f", amount.to_f/100) 

      amount_with_taxes_in_hundreds = sprintf("%.2f", amount_with_taxes.to_f/100)
      # Else proceed to save data and notify customer via text and email (plus tax and merchant name)
      # return "#{response.uri}, #{response.transaction_number}, #{response.source.last_four}, #{response.on_behalf_of.customer_uri}"
      @message = Message.new
      @name = (user.card_name.present?) ? " " + user.card_name.split.first : ''
      if merchant.tax_rate == "0"
        @message.send_and_save_message(11, merchant.rhombus_number, user.phone_number, 
              "Thanks" + @name + ". A payment of $#{amount_in_hundreds} was sent to #{merchant.business_name}.")
      else
        @message.send_and_save_message(11, merchant.rhombus_number, user.phone_number, 
          "Thanks" + @name + ". A payment of $#{amount_with_taxes_in_hundreds} plus taxes and fees set by #{merchant.business_name} was sent.")
      end
      
      # Send to merchant's messaging channel
      RealtimeStreamService.send_message_via_number(user.phone_number, merchant.rhombus_number, @message.text, @message.created_at, true)

      # assign txn num and save txn
      transaction_number = self.generate_number

      rhombus_fee_amt = sprintf("%.2f", rhombus_fee.to_f/100)
      amount_less_fees = amount_with_taxes_in_hundreds.to_f - rhombus_fee_amt.to_f - (((amount_with_taxes_in_hundreds.to_f * 0.029) + 0.3).round(2))

      self.save_transaction(transaction_uri: response.id, transaction_type: 1, 
          amount: amount_in_hundreds, transaction_number: transaction_number, amount_less_fees: amount_less_fees,
          description: "Payment to #{merchant.email}. #{merchant.business_name}. rhombus number: #{merchant.rhombus_number}", 
          from: user.phone_number, to: merchant.rhombus_number, status: response.paid, transaction_available_at: response.created, 
          last_four: response.card.last4, expiration_month: response.card.exp_month, expiration_year: response.card.exp_year, 
          card_type: response.card.type, card_name: response.card.name, tax_rate: merchant.tax_rate, 
          on_behalf_of_uri: merchant.stripe_access_token, referenced_merchant_id: merchant.id, user_id: user.id, notes: message,
          amount_with_taxes: sprintf("%.2f", response.amount.to_f/100))
    
      EmailingService.send_receipt( merchant_email: merchant.email, to: user.email, merchant_name: merchant.business_name, 
            transaction_number: transaction_number, transaction_date: self.created_at, text: message, amount: amount_in_hundreds,
            amount_with_taxes: amount_with_taxes_in_hundreds, currency: "$", business_phone: merchant.business_phone )

      self.receipt_sent_at = Time.zone.now                       # change this later to use timezone??
      self.save                                                  # Put a save check here later

      return self.id, amount_in_hundreds, amount_with_taxes_in_hundreds, amount_less_fees, transaction_number, response.id
    rescue Stripe::CardError => e
      # Since it's a decline, Stripe::CardError will be caught
      body = e.json_body
      err  = body[:error]

      @message = Message.new
      @message.send_and_save_message(18, merchant.rhombus_number, user.phone_number, 
            "Your payment to #{merchant.business_name} failed because: #{err[:message]}")

      EmailingService.charge_failure_notification(to: merchant.email, customer_email: user.email, customer_phone: user.phone_number,
        card_name: user.card_name, last_four: user.last_four, text: message, business_phone: merchant.business_phone,
        rhombus_number: merchant.rhombus_number, dump: err, to_merchant: true)
      return "failed"
    rescue Stripe::StripeError => e
      body = e.json_body
      err  = body[:error]
      EmailingService.charge_failure_notification(to: merchant.email, customer_email: user.email, customer_phone: user.phone_number,
        card_name: user.card_name, last_four: user.last_four, text: message, business_phone: merchant.business_phone,
        rhombus_number: merchant.rhombus_number, dump: err, to_merchant: false)
      return "failed"
    rescue StandardError => err
      EmailingService.charge_failure_notification(to: merchant.email, customer_email: user.email, customer_phone: user.phone_number,
        card_name: user.card_name, last_four: user.last_four, text: message, business_phone: merchant.business_phone,
        rhombus_number: merchant.rhombus_number, dump: err, to_merchant: false)
      return "failed"
    end
  end
   
  def merchant_transaction_details(debit_data, merchant, user, message)     

    self.save_transaction(transaction_uri: debit_data[5], transaction_type: 2, amount: debit_data[1], amount_less_fees: debit_data[3], 
        description: "Payment from #{user.email}. Card name: #{user.card_name}. Last four: #{user.last_four}.", 
        from: user.phone_number, to: merchant.rhombus_number, tax_rate: merchant.tax_rate,
        transaction_number: debit_data[4], referenced_user_id: user.id, referenced_customer_transaction_id: debit_data[0], 
        last_four: user.last_four, card_name: user.card_name, card_type: user.card_type, user_id: merchant.id, notes: message, amount_with_taxes: debit_data[2], 
        receipt_sent_at: Time.zone.now)                         # change this later

    EmailingService.send_payment_notification(to: merchant.email, card_name: user.card_name, last_four: user.last_four, 
        card_type: user.card_type, customer_email: user.email, customer_phone: user.phone_number, text: message, 
        transaction_number: debit_data[4], stripe_txn_number: debit_data[5], transaction_date: self.created_at, 
        amount_less_fees: debit_data[3], amount_with_taxes: debit_data[2], rhombus_number: merchant.rhombus_number, currency: "$")

    return self.id                                              # Put a save check here later
  end  

  def owner_transaction_details(debit_data, credit_data, merchant, user, message)  
      
    owner = User.find_by(email: Rails.application.secrets.dashboard_email)

    self.save_transaction(transaction_uri: debit_data[5], transaction_type: 0,
      amount: debit_data[3], amount_less_fees: debit_data[3], transaction_number: debit_data[4],
      description: "Payment from #{user.email}. Name on card: #{user.card_name}. Last four: #{user.last_four} to #{merchant.email}", 
      from: user.phone_number, to: merchant.rhombus_number, tax_rate: merchant.tax_rate, last_four: user.last_four,
      referenced_user_id: user.id, referenced_customer_transaction_id: debit_data[0], user_id: owner.id, notes: message, 
      amount_with_taxes: debit_data[2], referenced_merchant_transaction_id: credit_data, 
      referenced_merchant_id: merchant.id)                                   # Put a save check here later
  end

  def save_transaction(options = {})
    #debugger   		
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
    self.receipt_sent_at  = options[:receipt_sent_at] if options[:receipt_sent_at]
   	
   	self.last_four = options[:last_four] if options[:last_four]
   	self.expiration_month = options[:expiration_month] if options[:expiration_month]
   	self.expiration_year = options[:expiration_year] if options[:expiration_year]
   	self.card_type = options[:card_type] if options[:card_type]
   	self.card_name	= options[:card_name] if options[:card_name]
   	
   	self.tax_rate = options[:tax_rate] if options[:tax_rate]
   	self.on_behalf_of_uri = options[:on_behalf_of_uri] if options[:on_behalf_of_uri]
   	self.referenced_user_id = options[:referenced_user_id] if options[:referenced_user_id]
  	self.referenced_customer_transaction_id = options[:referenced_customer_transaction_id] if options[:referenced_customer_transaction_id]
  	self.user_id = options[:user_id] if options[:user_id]

   	self.notes = options[:notes] if options[:notes]
   	self.amount_with_taxes = options[:amount_with_taxes] if options[:amount_with_taxes]
   	self.referenced_merchant_transaction_id = options[:referenced_merchant_transaction_id] if options[:referenced_merchant_transaction_id]
   	self.referenced_merchant_id = options[:referenced_merchant_id] if options[:referenced_merchant_id]        

   	self.save 										# add a check here later
   end
end


# Can I grab this info from Stripe ?? #account_number: "", account_type: "", account_name: "", routing_number: ""
#self.zip_code = options[:zip_code] if options[:zip_code]
#self.account_number = options[:account_number] if options[:account_number]
#self.account_type = options[:account_type] if options[:account_type]
#self.account_name = options[:account_name] if options[:account_name]
#self.routing_number = options[:routing_number] if options[:routing_number]
#self.refund_reason = options[:refund_reason] if options[:refund_reason]

