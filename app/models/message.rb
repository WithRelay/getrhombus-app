class Message < ActiveRecord::Base
	require 'uri'
	# Move to user and order models
	Balanced.configure('cb51061889c511e2ac81026ba7cd33d0') 
	
	###### In User model
    def balanced_associate_token_with_customer
   		
   		# Create or update customer on Balanced
   		######## if uri already exist => update card info
   		customer = Balanced::Customer.find('/v1/customers/CU7gMTGKh2yGHYn1lUxH9STS')
   		######## else add uri to db
   		customer = Balanced::Customer.new.save
   		######## end

   		######## Add response check and save info before proceeding

   		# Set uri token
   		token = "CC5iSapZxwZJ0H97eFKsuQVW"

   		######## if it is a credit card bank account
   		response = customer.add_card('/v1/marketplaces/TEST-MP6bP0y8O10lBsBfh8oMGhE4/cards/' + "#{token}")
   		######## elsif it is a bank account
   		response = customer.add_bank_account("/v1/bank_accounts/" + "#{token}")
   		###### end

		######## Process response here
   	end
   	##### End for User Model



   	###### In Transaction Model
   	def balanced_debit_customer_card
   		###### Find uri from DB
   		uri = '/v1/customers/CU6vs1tjxBtifgTuzKjCGtVS'
   		customer = Balanced::Customer.find(uri)
		customer.debit(:amount => 10)
		###### handle response / save data
   	end

   	def balanced_credit_merchant_bank_account
   		####### Find uri from DB
  		uri = '/v1/customers/CU5f64LhFMO8cf7N1sQSRVOo'
   		customer = Balanced::Customer.find(uri)
   		customer.credit(:amount => 10)
   		###### handle response / save data
   	end

   	def balanced_payout_to_marketplace_bank_account
   		marketplace.owner_customer.credit(:amount => 100000, :description => "Collect revenue")
   		##### handle response and save
   	end

   	def balanced_add_account_to_marketplace_owner
   		marketplace.owner_customer.add_bank_account(uri)
   		##### handle response and save uri
   	end

   	def balanced_issue_refund_to_card
   		uri = '/v1/customers/CU5f64LhFMO8cf7N1sQSRVOo'
   		customer = Balanced::Customer.find(merchant_uri)
   		customer.debit(:amount => 10)
   		#payee_uri = '/v1/customers/CU5f64LhFMO8cf7N1sQSRVOo'   		
   		#customer = Balanced::Customer.find(uri)
   		#customer.credit(:amount => 10)
   	end

   	def balanced_confirm_bank_account
   	end
   	###### End for Transaction Model


   	# For sending any text message
	def nexmo_send_text_message
		url = URI.encode_www_form([["api_key", "0ed6ecb8"],
					["api_secret", "b4f769d8"],
					["from", "<redacted_phone_number>"],
					["to", "<redacted_phone_number>"],
					["text", "are u eddy?"],

				])
		@response = HTTParty.post('https://rest.nexmo.com/sms/json?'+ url, :headers => {"Content-Type" => "application/x-www-form-urlencoded"} )
	end

	# For signing up users
	def nexmo_send_signup_text(number)
		url = URI.encode_www_form([["api_key", "0ed6ecb8"],
					["api_secret", "b4f769d8"],
					["from", "<redacted_phone_number>"],
					["to", number],
					["text", "www.getrhombus.com/signup?number=" + "#{number}"],

				])
		response = HTTParty.post('https://rest.nexmo.com/sms/json?'+ url, :headers => {"Content-Type" => "application/x-www-form-urlencoded"} )
	end

	# For merchants signing up
	def nexmo_search_and_buy_number(country)
		api_key: '<redacted_api_key>'
		api_secret: '<redacted_api_secret>'
		response = HTTParty.get('https://rest.nexmo.com/number/search/'+ api_key + "/" + api_secret + "/" + country + "?features=SMS,VOICE&size=1")
		###### Check response here...see shelflet code
		msisdn = response["numbers"].first["msisdn"]
		#response = HTTParty.post('https://rest.nexmo.com/number/buy/'+ api_key + "/" + api_secret + "/" + country + "/" + msisdn)
		###### Check response here...see shelflet code
		###### Save number to merchant
	end

	# For saving any text received or sent
	def save_text_from_user		
		@message = Message.new
		@message.text = params[:text]
		@message.save
		render status: 200
	end

end
