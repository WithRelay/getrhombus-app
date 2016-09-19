class Transaction < ActiveRecord::Base

  include Transactionable
  include CSVHandler
  # scope :ordering, -> { order(:DESC) }

  has_one :message
<<<<<<< HEAD
  has_one :refund, inverse_of: :refund
=======
  belongs_to :user, counter_cache: true
  belongs_to :refund, inverse_of: :transactions
>>>>>>> f63f52b9b2dd659ebe2b0707f6a21db258a7113e

  belongs_to :hashtag
  belongs_to :user, counter_cache: true
  belongs_to :team, class_name: "User", counter_cache: true

  belongs_to :refund, inverse_of: :transactions

  # Why am I passing an array in here?
  # Capture can change transaction status and date
  # Each transaction generates 3 rows. This will be normalized in future updates
  # This method support captured payment, charge a customer and sms payment
  # does this include hashtag_id
  # send in a hash instaed to PaymentService
  def self.charge_customer_card(amt_ary, merchant, user, message, capture=true) 
    begin    
      amount = amt_ary[0]
    	tax_percent = (((merchant.tax_percent.to_f)/100) + 1)                     # apply tax, default is 0
    	amount_with_taxes = (amount.to_f * tax_percent).round(0)			
      rhombus_fee = ((Rails.application.secrets.application_fee_percent / 100) * amount_with_taxes.to_f).round(0)

      payment_response_array = PaymentService.charge(amount_with_taxes, merchant, user, message, capture)
      response = payment_response_array[0]

      unless response
        if payment_response_array[2]
          message = Message.send_and_save_message(merchant.rhombus_number, user.phone_number, "Your payment to #{merchant.org_name} failed because: #{err[:message]}")
          # Send to merchant's messaging channel
          RealtimeStreamService.send_message_via_number(user.phone_number, merchant.rhombus_number, message.text, message.created_at, true) if message        
        end
        EmailingService.charge_failure_notification(to: merchant.email, customer_email: user.email, customer_phone: user.phone_number,
            card_name: user.card_name, last_four: user.last_four, text: message, org_phone: merchant.org_phone,
            rhombus_number: merchant.rhombus_number, dump: err, to_merchant: payment_response_array[2])
        return
      end

      amount_in_hundreds = sprintf("%.2f", amount.to_f/100)
      amount_with_taxes_in_hundreds = sprintf("%.2f", amount_with_taxes.to_f/100)
      
      send_text_receipt(user, merchant, response, amount_in_hundreds, amount_with_taxes_in_hundreds)
      
      transaction_number = generate_number
      rhombus_fee_amt = sprintf("%.2f", rhombus_fee.to_f/100)
      amount_less_fees = amount_with_taxes_in_hundreds.to_f - rhombus_fee_amt.to_f - (((amount_with_taxes_in_hundreds.to_f * 0.029) + 0.3).round(2))

      # Note since relationship between user and card is one to one, when merchant and owner info is saved,
      # it is pulled from user profile and not transaction data. This changes with x to many relationships.
      # Add hashtag_id option
      create(transaction_uri: response.id, transaction_type: 1, amount: amount_in_hundreds, 
          transaction_number: transaction_number, amount_less_fees: amount_less_fees, rhombus_fee: rhombus_fee_amt,
          description: "Payment to #{merchant.email}. #{merchant.org_name}. rhombus number: #{merchant.rhombus_number}", 
          from: user.phone_number, to: merchant.rhombus_number, status: response.status, transaction_available_at: response.created, 
          last_four: response.source.last4, expiration_month: response.source.exp_month, expiration_year: response.source.exp_year, 
          card_type: response.source.brand, card_name: response.source.name, tax_percent: merchant.tax_percent, 
          on_behalf_of_uri: merchant.stripe_access_token, team_id: merchant.id, user_id: user.id, notes: message,
          amount_with_taxes: sprintf("%.2f", response.amount.to_f/100), currency: response.currency, captured: response.captured)
    
      # Also need to email merchant here too
      # So move this to another method below just like send text receipt
      EmailingService.send_receipt( merchant_email: merchant.email, to: user.email, merchant_name: merchant.org_name, 
            transaction_number: transaction_number, transaction_date: self.created_at, text: message, amount: amount_in_hundreds,
            amount_with_taxes: amount_with_taxes_in_hundreds, org_phone: merchant.org_phone, currency: response.currency)


      # change this later to use timezone??, Put a save check here later
      self.receipt_sent_at = Time.zone.now                      

      # delete these 4 lines
      #debit_data = [self.id, amount_in_hundreds, amount_with_taxes_in_hundreds, amount_less_fees, transaction_number, 
       #               response.id, rhombus_fee_amt, response.currency, response.captured]
      #merchant_txn_id = merchant_transaction_details(debit_data, merchant, user, message)
      #owner_transaction_details(debit_data, merchant_txn_id, merchant, user, message)      
      #self.referenced_merchant_transaction_id = merchant_txn_id
      
      self.save
      self.id
    rescue StandardError => err
      EmailingService.charge_failure_notification(to: merchant.email, customer_email: user.email, customer_phone: user.phone_number,
        card_name: user.card_name, last_four: user.last_four, text: message, org_phone: merchant.org_phone,
        rhombus_number: merchant.rhombus_number, dump: err, to_merchant: false)
      return
    end
  end

  # receipts for capture should be different
  def send_text_receipt(user, merchant, response, amount_in_hundreds, amount_with_taxes_in_hundreds)
    message = Message.new
    name = (user.card_name.present?) ? " " + user.card_name.split.first : ''
    if merchant.tax_percent == "0"
      message.send_and_save_message(merchant.rhombus_number, user.phone_number, 
        "Thanks" + name + ". A payment of #{amount_in_hundreds} (#{response.currency}) was sent to #{merchant.org_name}.")
    else
      message.send_and_save_message(merchant.rhombus_number, user.phone_number, 
        "Thanks" + name + ". A payment of #{amount_with_taxes_in_hundreds} (#{response.currency}) plus taxes and fees set by #{merchant.org_name} was sent.")
    end
    # Send to merchant's messaging channel
    RealtimeStreamService.send_message_via_number(user.phone_number, merchant.rhombus_number, message.text, message.created_at, true)
  end

 
=begin  
  def merchant_transaction_details(debit_data, merchant, user, message)  
    # Put a save check here later
    transaction = create(transaction_uri: debit_data[5], transaction_type: 2, amount: debit_data[1], amount_less_fees: debit_data[3], 
        description: "Payment from #{user.email}. Card name: #{user.card_name}. Last four: #{user.last_four}.", 
        from: user.phone_number, to: merchant.rhombus_number, tax_percent: merchant.tax_percent,
        transaction_number: debit_data[4], referenced_user_id: user.id, referenced_customer_transaction_id: debit_data[0], 
        last_four: user.last_four, card_name: user.card_name, card_type: user.card_type, user_id: merchant.id, notes: message, amount_with_taxes: debit_data[2], 
        receipt_sent_at: Time.zone.now, currency: debit_data[7], captured: debit_data[8])                         # change this time thing later

    EmailingService.send_payment_notification(to: merchant.email, card_name: user.card_name, last_four: user.last_four, 
        card_type: user.card_type, customer_email: user.email, customer_phone: user.phone_number, text: message, 
        transaction_number: debit_data[4], stripe_txn_number: debit_data[5], transaction_date: transaction.created_at, 
        amount_less_fees: debit_data[3], amount_with_taxes: debit_data[2], rhombus_number: merchant.rhombus_number, currency: debit_data[7])

    transaction.id                                              
  end  


  def owner_transaction_details(debit_data, merchant_txn_id, merchant, user, message)        
    owner = User.find_by(email: Rails.application.secrets.dashboard_email)
    
    # Put a save check here later
    create(transaction_uri: debit_data[5], transaction_type: 0,
      amount: debit_data[6], amount_less_fees: debit_data[3], transaction_number: debit_data[4],
      description: "Payment from #{user.email}. Name on card: #{user.card_name}. Last four: #{user.last_four} to #{merchant.email}", 
      from: user.phone_number, to: merchant.rhombus_number, tax_percent: merchant.tax_percent, last_four: user.last_four,
      referenced_user_id: user.id, referenced_customer_transaction_id: debit_data[0], user_id: owner.id, notes: message, 
      amount_with_taxes: debit_data[2], referenced_merchant_transaction_id: merchant_txn_id, 
      team_id: merchant.id, currency: debit_data[7], captured: debit_data[8])                                   
  end
=end

<<<<<<< HEAD
  def self.process_captured_payment()
    # call charge customer here
  end
=======
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
    self.currency = options[:currency] if options[:currency]        

   	self.save 										# add a check here later
  end

end
>>>>>>> f63f52b9b2dd659ebe2b0707f6a21db258a7113e

end


