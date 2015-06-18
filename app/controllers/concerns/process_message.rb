module ProcessMessage
	extend ActiveSupport::Concern

	require "uri"
	require 'rack/utils'


	def process_message(request, params)
		return if params[:text].blank?

		text = params[:text].strip
		user = User.find_by(phone_number: params[:msisdn])
		merchant = User.find_by(rhombus_number: params[:to])
		amount = is_payment?(text)
		if amount
			if user
				if is_customer_account_complete?(request, params, user)
					amount = to_cents(amount)
					if is_amount_under_limit?(request, params, amount)
						if is_merchant_active?(request, params, merchant)
							if is_merchant_account_complete?(request, params, merchant)
								process_payment(amount, merchant, user, text, request)
							end
						end
					end
				end
			else
				# paymennt message but user doesnt exist. save in messages and send a response
				merchant_name = merchant.business_name ? merchant.business_name : "Rhombus"
				short_link = UrlShortenerService.shorten_link("https://www.getrhombus.com/signup?num=#{params[:msisdn]}&referrer_num=#{params[:to]}&referrer=#{merchant_name}")
				send_response(16, params[:to], params[:msisdn], "Hi there, thanks for reaching out...to send a payment, sign up here. Thanks! => #{short_link}")
				save_inbound_text(request.query_string, msg_code = 6)
				return
			end
		elsif !user
			save_inbound_text(request.query_string, msg_code = 4)
			if is_signup(text)
				merchant_name = merchant.business_name ? merchant.business_name : "Rhombus"
				short_link = UrlShortenerService.shorten_link("https://www.getrhombus.com/signup?num=#{params[:msisdn]}&referrer_num=#{params[:to]}&referrer=#{merchant_name}")
				send_response(14, params[:to], params[:msisdn], "Hi there, thanks for reaching out...to chat with us or send a payment, sign up here: #{short_link}")
			end
		else
			# user exist, but not a payment message...save in messages
			save_inbound_text(request.query_string, msg_code = 5)
			# until nexmo can give use concatenated messages..i think they do now (06/14/14)
		end
	end

	# refactor Transaction model
	def process_payment(amount, merchant, user, text, request)
		# save and pubnub
    	new_message = save_inbound_text(request.query_string, msg_code = 1)
		
		@customer_transaction = Transaction.new
		debit_data = @customer_transaction.charge_customer_card(amount, merchant, user, text)
		
		# Save transaction id
		if (!new_message.id.blank?)
		  new_message.update(transaction_id: debit_data[0])
		end
		
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
		#currencies = ["$", "+"]
		#return amount if currencies.include? text.chr && is_number?(amount)
		#return amount if text.chr == "$" || URI.escape(text.chr) == "%C2%A4" && is_number?(amount)
		return amount if text.chr == "$" || URI.escape(text.chr) == "%C2%A4" || text.chr == "+" && is_number?(amount)
		return false
	end


	def get_number(text)
		return (text.split(" ", 2).first[1..-1])
	end


	def is_number?(var)
  	   	true if Float(var) rescue false
	end


	def is_signup?(text)
		words = ['signup', 'sign-up', 'give', 'pay', 'buy', 'donate']
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
    RealtimeStreamService.send_message_via_number(from, to, message, @message.created_at, true)
	end

	
	def save_inbound_text(query, msg_code, transaction_id = 0)						# if not for payment, transaction_id = 0
		query_hash = Rack::Utils.parse_nested_query(query)      					# deal with some weird params from nexmo
		@message = Message.new 
		@message.save_text(from: query_hash['msisdn'], to: query_hash['to'], 
			network_code: query_hash["network-code"], messageId: query_hash['messageId'], message_timestamp: query_hash["message-timestamp"],
			text: query_hash['text'], message_code: msg_code, transaction_id: transaction_id)
			
	  # Send to merchant's messaging channel
	  RealtimeStreamService.send_message_via_number(query_hash['msisdn'], query_hash['to'], query_hash['text'], @message.created_at)
	  @message
	end

	
	def save_delivery_receipts(query)
		query_hash = Rack::Utils.parse_nested_query(query)     						# deal with some weird params from nexmo
		begin
			@message = Message.find_by(id: query_hash["client-ref"]) 
		rescue
			# if somehow the message id doesnt exist
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

