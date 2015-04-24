module ProcessMessage
	extend ActiveSupport::Concern

	require "uri"
	require 'rack/utils'


	def process_message(request, params)
		return if params[:text].blank?

		text = params[:text].strip

		user = User.find_by(phone_number: params[:msisdn])		
		amount = is_payment?(text)
		if amount
			if user
				if is_customer_account_complete?(request, params, user)
					amount = to_cents(amount)
					if is_amount_under_limit?(request, params, amount)
						merchant = User.find_by(rhombus_number: params[:to])
						if is_merchant_active?(request, params, merchant)
							if is_merchant_account_complete?(request, params, merchant)
								process_payment(amount, merchant, user, text, request)
							end
						end
					end
				end
			else
				# if user doesnt exist. save in messages and send a response
				save_inbound_text(request.query_string, msg_code = 6)
				send_response(16, params[:to], params[:msisdn], 
					"Please follow the link below to create an account and then resend your payment. Thanks! => https://www.getrhombus.com/signup?num=#{params[:msisdn]}")
				return
			end
		elsif !user && is_signup?(text)
			# how will view handle retrieving system message? does it matter?
			# save in messages and send a response
			save_inbound_text(request.query_string, msg_code = 4)
			send_response(14, params[:to], params[:msisdn], 
				"To start using Rhombus, follow the link to complete your signup: https://www.getrhombus.com/signup?num=#{params[:msisdn]}")
		else
			# save and pubnub
			# save in messages
			save_inbound_text(request.query_string, msg_code = 5)
			# until nexmo can give use concatenated messages..i think they do now (06/14/14)
		end
	end

	# refactor Transaction model
	def process_payment(amount, merchant, user, text, request)
		@customer_transaction = Transaction.new
		debit_data = @customer_transaction.charge_customer_card(amount, merchant, user, text)
		
		# save and pubnub
		save_inbound_text(request.query_string, msg_code = 1, debit_data[0])

		# if no error from api or saving process, proceed to save transaction details for merchant
		if debit_data != "failed"
			@merchant_transaction = Transaction.new
			credit_data = @merchant_transaction.merchant_transaction_details(debit_data, merchant, user, text)
										
			# if credit_data != "failed"					# saved successfully that is
			# set the merchant transaction id in the customer referenced transaction id
			@customer_transaction.referenced_merchant_transaction_id = credit_data # or @merchant_transaction.id
			@customer_transaction.save

			#Facilitation info. Save customer and merchant transaction ids
			@marketplace_transaction = Transaction.new
			@marketplace_transaction.owner_transaction_details(debit_data, credit_data, merchant, user, text)#@merchant_transaction.id, @user, text)
			# end
		else
			return
		end	
		# see number 20. Used for payment system outage
		# send_response(20, params[:to], params[:msisdn], "Thank you for sending a payment with rhombus. We're currently experiencing a system outage. We will notify you once the outage is resolved. Thanks!")
	end


	def is_customer_account_complete?(request, params, user)
		return true if user.customer_uri
		save_inbound_text(request.query_string, msg_code = 7)
		# notify user
		send_response(17, params[:to], params[:msisdn], 
			"Please follow the link below to complete your account and then resend your payment. Thanks! => https://www.getrhombus.com/signin")
		
		# also notify merchant via PUSH and email

		return false
	end


	def is_merchant_active?(request, params, merchant)
		return true if merchant.is_active
		save_inbound_text(request.query_string, msg_code = 9)

		# notify user
		send_response(19, params[:to], params[:msisdn], "Thank you for sending a payment with Rhombus, but the merchant hasn't completed the account to receive payments.")
		
		# also notify merchant via push and email
		
		return false
	end


	def is_merchant_account_complete?(request, params, merchant)
		return true if !merchant.stripe_access_token.blank?
		save_inbound_text(request.query_string, msg_code = 9)

		# notify user
		send_response(19, params[:to], params[:msisdn], "Thank you for sending a payment with Rhombus, but the merchant hasn't completed the account to receive payments.")
		
		# also notify merchant via PUSH and email
		
		return false
	end


	def is_amount_under_limit?(request, params, amount)
		return true if amount <= 1500000
		# send message over limit
		# save in messages and send a response
		save_inbound_text(request.query_string, msg_code = 2)
		
		# notify user
		send_response(12, params[:to], params[:msisdn], "Sorry, we are unable to make payments above 15,000 dollars. But you can send in smaller amounts. Thanks!")

		# also notify merchant via PUSh and email
		
		return false
	end


	def is_payment?(text)
		amount = get_number(text)
		# might need to change this for other countries
		return amount if text.chr == "$" || URI.escape(text.chr) == "%C2%A4" && is_number?(amount)
		return false
	end


	def get_number(text)
		return (text.split(" ", 2).first[1..-1])
	end


	def is_number?(var)
  	   	true if Float(var) rescue false
	end


	def is_signup?(text)
		words = ['signup', 'sign-up', 'give', 'pay']
		return true if words.include? text.downcase.gsub(/\s+/, "")  
		return false
	end


	def to_cents(var)
		return ((var.to_f.round(2).abs)*100).round
	end


	def send_response(msg_code, to, from, message) 
		@message = Message.new 				
		@message.send_and_save_message(msg_code, to, from, message)
		
		# Send to merchant's messaging channel
    RealtimeStreamService.send_message_via_number(to, from, message, @message.created_at)
	end

	
	def save_inbound_text(query, msg_code, transaction_id = 0)						# if not for payment, transaction_id = 0
		query_hash = Rack::Utils.parse_nested_query(query)      					# deal with some weird params from nexmo
		@message = Message.new 
		@message.save_text(from: query_hash['msisdn'], to: query_hash['to'], 
			network_code: query_hash["network-code"], messageId: query_hash['messageId'], message_timestamp: query_hash["message-timestamp"],
			text: query_hash['text'], message_code: msg_code, transaction_id: transaction_id)
			
    # Send to merchant's messaging channel
    RealtimeStreamService.send_message_via_number(query_hash['msisdn'], query_hash['to'], query_hash['text'], @message.created_at)
	end

	
	def save_delivery_receipts(query)
		query_hash = Rack::Utils.parse_nested_query(query)     						# deal with some weird params from nexmo
		begin
			@message = Message.find_by(id: query_hash["client-ref"]) 
		rescue
			@message = Message.new
			@message.save_text(from: query_hash["to"], network_code: query_hash['network-code'], messageId: query_hash['messageId'], 
				to: query_hash["msisdn"], status_delivery: query_hash["status"], err_code: query_hash['err-code'], message_price: query_hash["price"], 
				scts: query_hash['scts'], message_timestamp: query_hash["message-timestamp"], 
				client_ref: query_hash['client-ref'], message_code: 8)
		else
			if @message
				@message.save_text(status_delivery: query_hash["status"], err_code: query_hash['err-code'],
				scts: query_hash['scts'], message_timestamp: query_hash["message-timestamp"])
			end
		end
		#if !query_hash.has_key?("network-code")				# Looks like nexmo doesnt always provide this...not sure
			#query_hash['network-code'] = ""
		#end
	end
	
end

=begin
def receive_text_message
		#params[:to] = "<redacted_phone_number>"
		#params[:msisdn] = "<redacted_phone_number>" 			# "<redacted_phone_number>"
		render :text => ""							# for nexmo

		process_message(params)
		if params[:text] != ""        				# Ensure there is a text query string

			text = params[:text].strip
			amount = get_number(text)
			
			if text.chr == "$" || URI.escape(text.chr) == "%C2%A4" and is_number?(amount)	# Ensure text is valid for making payments

				amount = to_cents(amount)

				if amount >= 100 and amount <= 1500000

					begin
						# find the user
						# change this to if statement##################################################
						@user = User.find_by!(phone_number: params[:msisdn])
					rescue StandardError => e
						# if user doesnt exist
						# save in messages and send a response
						save_inbound_text(request.query_string, msg_code = 6)
						@message = Message.new
						@message.nexmo_send_text_message(16, params[:to], params[:msisdn], "Please follow the link below to create an account and then resend your payment. Thanks! => https://www.getrhombus.com/signup?num=#{params[:msisdn]}")
						return
					else						
						
						if @user.customer_uri.blank?
							save_inbound_text(request.query_string, msg_code = 7)
							@message = Message.new
							@message.nexmo_send_text_message(17, params[:to], params[:msisdn], "Please follow the link below to complete your account and then resend your payment. Thanks! => https://www.getrhombus.com/signin")
						else 
							# change this to if statement##################################################

							##### this needs to be in an exception block or use if statement
							# find_by  returns nil...find throws exception
							# no more uniquesness check for this...nexmo should return unique numbers
							@merchant = User.find_by(rhombus_number: params[:to])
							####
							if @merchant.is_active
								if @merchant.stripe_access_token.blank?
									save_inbound_text(request.query_string, msg_code = 9)
									@message = Message.new
									@message.nexmo_send_text_message(19, params[:to], params[:msisdn], "Thank you for sending a payment with Rhombus, but the merchant hasn't completed the account to receive payments.")
								else
									@customer_transaction = Transaction.new
									debit_data = @customer_transaction.charge_customer_card(amount, @merchant, @user, text)
									save_inbound_text(request.query_string, msg_code = 1, debit_data[0])
									
									# if no error from api or saving process, proceed to save transaction details for merchant
									if debit_data != "failed"
										@merchant_transaction = Transaction.new
										credit_data = @merchant_transaction.merchant_transaction_details(debit_data, @merchant, @user, text)
										
										# if credit_data != "failed"					# saved successfully that is
											# set the merchant transaction id in the customer referenced transaction id
											@customer_transaction.referenced_merchant_transaction_id = credit_data # or @merchant_transaction.id
											@customer_transaction.save

											# Facilitation info. Save customer and merchant transaction ids
											@marketplace_transaction = Transaction.new
											@marketplace_transaction.owner_transaction_details(debit_data, credit_data, @merchant, @user, text)#@merchant_transaction.id, @user, text)
										# end
									else
										return
									end	
									# see number 20. Used for payment system outage
									# @message = Message.new							
							    	# @message.nexmo_send_text_message(20, params[:to], params[:msisdn], "Thank you for sending a payment with rhombus. We're currently experiencing a system outage. We will notify you once the outage is resolved. Thanks!")
								end	
							else
								save_inbound_text(request.query_string, msg_code = 9)
								@message = Message.new
								@message.nexmo_send_text_message(19, params[:to], params[:msisdn], "Thank you for sending a payment with Rhombus, but the merchant hasn't completed the account to receive payments.")
							end						
						end				
					end
				elsif amount > 1500000

					# save in messages and send a response
					save_inbound_text(request.query_string, msg_code = 2)
					@message = Message.new 							
					@message.nexmo_send_text_message(12, params[:to], params[:msisdn], 
						"Sorry, we are unable to make payments above 15,000 dollars. But you can send in smaller amounts. Thanks!")
				
				else
					
					# save in messages and send a response
					save_inbound_text(request.query_string, msg_code = 3)
					@message = Message.new 											
					@message.nexmo_send_text_message(13, params[:to], 
						params[:msisdn], "Sorry, we are unable to make payments below 1 dollar.")
				
				end	
			# for signing up
			elsif text.downcase.gsub(/\s+/, "") == "signup" || text.downcase.gsub(/\s+/, "") == "sign-up" || text.downcase.gsub(/\s+/, "") == "give" || text.downcase.gsub(/\s+/, "") == "pay"

				# save in messages and send a response
				save_inbound_text(request.query_string, msg_code = 4)
				@message = Message.new 				
				@message.nexmo_send_text_message(14, params[:to], params[:msisdn], 
					"To start using Rhombus, follow the link to complete your signup: https://www.getrhombus.com/signup?num=#{params[:msisdn]}")
			
			else 	
				
				# for messages we cant parse sucessfully
				# save in messages
				save_inbound_text(request.query_string, msg_code = 5)
				# until nexmo can give use concatenated messages..i think they do now (06/14/14)
				
				@message = Message.new
				@message.nexmo_send_text_message(15, params[:to], params[:msisdn], 
					'Sorry we did not understand your text. You can signup by texting "signup" or make payments by texting "$Amount Description". Thanks!')
			
			end
		end
	end
=end