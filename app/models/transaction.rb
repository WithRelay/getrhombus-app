class Transaction < ActiveRecord::Base

	Balanced.configure('cb51061889c511e2ac81026ba7cd33d0') 
	
   def balanced_debit_customer_card
   	###### Find info below from DB
      #payee_uri = '/v1/customers/CU6CITLjN3SrRYqoc9EnraLd'
      payee_uri = "/v1/customers/CU1UTgvrRR6pVLksnVpv4l6T"     # will throw insufficient fund
      #user.id = "12"
      customer_last_name = "Paul Jones"
      customer_last_four = "2222"
      #### find using number
      merchant_uri = "/v1/customers/CU20htXmtjNsleBvmhwai9sP"
      merchant_name = "Tiny"
      amount = 50
   	########################################
      customer = Balanced::Customer.find(payee_uri)            # Add a check here later
      begin
   	   response = customer.debit(:amount => amount,
                  :on_behalf_of_uri => merchant_uri,
                  :appears_on_statement_as => merchant_name,
                  :description => "#{customer_last_name}_#{customer_last_four}")
      rescue Exception => e        
         # Handle bad response
         failure_reason = e.response[:body]["category_code"]
         status_code = e.response[:body]["status_code"]
=begin
         # Notify customer on failed debit
         message = Message.new
         if amount > 100 and status_code == 402                   # How about 409???
            message.nexmo_send_text_message(<redacted_phone_number>, <redacted_phone_number>, 
              "Your payment of #{amount/100} dollars to #{merchant_name} failed because: #{failure_reason}.")
         elsif amount < 100 and status_code == 402
            message.nexmo_send_text_message(<redacted_phone_number>, <redacted_phone_number>, 
              "Your payment of #{amount} cents to #{merchant_name} failed because: #{failure_reason}.")
         elsif amount = 100 and status_code == 402
            message.nexmo_send_text_message(<redacted_phone_number>, <redacted_phone_number>, 
              "Your payment of #{amount/100} dollar to #{merchant_name} failed because: #{failure_reason}.")
         end
=end   
         # Notify marketplace owner of failed debit
         return e.response[:body], failure_reason, status_code, e.response[:body]["description"]
      else
         # Else proceed to save data etc
         ###### Save data and calls below
         #return "#{response.uri}, #{response.transaction_number}, 
                  #{response.source.last_four}, #{response.on_behalf_of.customer_uri}"
      end
   end


   def balanced_credit_merchant_bank_account                  # Call from balanced_debit_customer_card if debit succeeds
   	####### Find merchant uri from DB using phone number?
      customer_last_name = "Phil Matt"
      customer_last_four = "7777"
  	   merchant_uri = '/v1/customers/CU20htXmtjNsleBvmhwai9sP'
      ######################
   	customer = Balanced::Customer.find(merchant_uri)           # Add a check here later
      begin
    	response = customer.credit(:amount => 11111150,
            :description => "#{customer_last_name}_#{customer_last_four}",
            :appears_on_statement_as => "#{customer_last_name}_#{customer_last_four}")
      rescue Exception => e
         # Handle bad response
         return e, e.response[:body]["category_code"], e.response[:body]["status_code"],
                  e.response[:body]["description"]
         # Notify merchant and marketplace owner of failed credit

      else
         # Else proceed to save data etc
         #return "#{response.uri}, #{response.transaction_number}, #{response.source.last_four}, #{response.on_behalf_of.customer_uri}"
      end
   end


   def balanced_payout_to_marketplace_bank_account       # Call from balanced_debit_customer_card if debit succeeds
      customer_last_name = "Son Goku"
      customer_last_four = "1234"
      ###################
      marketplace = Balanced::Marketplace.mine                           # Add a check here later
      begin
   	   response = marketplace.owner_customer.credit(:amount => 10000000, 
            :description => "#{customer_last_name}_#{customer_last_four} fees",
            :appears_on_statement_as => "#{customer_last_name}_#{customer_last_four} fees")
   	rescue Exception => e
         # Handle bad response
         return e.response[:body]["category_code"], e.response[:body]["status"], 
               e.response[:body]["status_code"], e.response[:body]["description"]
         # Notify marketplace owner of failed credit
      else
         # Else process to save data #also returns credit_uri so save it
         return "#{response.uri}, #{response.status}" 
      end
   end

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


end
