module ProcessMessage
	extend ActiveSupport::Concern

	require 'rack/utils'

	# remove request string when merging with Ayo
	# search for remove
	# search for review


	def process_message(request, params)
		begin
			return if params[:text].blank?

			text = params[:text].strip
			user = User.find_by(phone_number: params[:msisdn])
			merchant = User.find_by(rhombus_number: params[:to])
			
			amount_array = check_for_payment(text)
			amount_array = check_for_tag(amount_array, merchant.id)

			if amount_array[0] || amount_array[2]

				if user && is_customer_account_complete?(request, params, user) && is_amount_under_limit?(request, params, amount_array[0])	

					if is_merchant_active?(request, params, merchant) && is_merchant_account_complete?(request, params, merchant)

						# process if (amount valid and tag_exist/not precedent) or (amount valid and no tag) or (no amount and tag_exist)
						if (amount_array[0] && !amount_array[5]) || (amount_array[0] && !amount_array[2]) || (!amount_array[0] && amount_array[2])
							process_payment(amount_array, merchant, user, text, request)
						
						# dont process if (amount valid and tag exist/precedent) or (amount not valid and tag exist/precedent)
						# do I need to even test for amount validity?
						elsif (amount_array[0] && amount_array[5]) || (!amount_array[0] && amount_array[5])
							# response here

						# respond if (amount not valid and no tag)
						elsif (!amount_array[0] && !amount_array[2])
							# response here

						end

						deprecation_warning(params[:to], params[:msisdn]) if amount_array[1] == "+"
					end
				
				else
					# payment message (raw amt or hashtag) but user doesnt exist. save in messages and send a response with payment captured link
					saved_message = save_inbound_text(request.query_string, msg_code = 6)
					merchant_name = merchant.business_name ? merchant.business_name : "Rhombus"

					# what if valid hashtag ??????
					# modify response to based on amt valid or tag precedent...what if amt invalid...

					if saved_message && saved_message.id.present? # send captured link only if message saved else something went wrong
						short_link = UrlShortenerService.shorten_link("https://www.getrhombus.com/signup?amt=#{amount_array[0]}&num=#{params[:msisdn]}
																		&referrer_num=#{params[:to]}&referrer=#{merchant_name}&mid=#{saved_message.id}")
						send_response(16, params[:to], params[:msisdn], "Hi there, thanks for reaching out...to send a payment, sign up here. Thanks! => #{short_link}")
					else
						# something went wrong
					end
					return
				end

			elsif !user
				save_inbound_text(request.query_string, msg_code = 4)
				
				is_signup = is_signup?(text)
				if is_signup
					merchant_name = merchant.business_name ? merchant.business_name : "Rhombus"
					short_link = UrlShortenerService.shorten_link("https://www.getrhombus.com/signup?num=#{params[:msisdn]}&referrer_num=#{params[:to]}&referrer=#{merchant_name}")
					send_response(14, params[:to], params[:msisdn], "To chat with us or send a payment, sign up here: #{short_link}")
				end

				if Message.where(from: params[:msisdn], to: params[:to]).limit(2).count < 2 && !is_signup
			        first_name = (merchant.first_name.present?) ? "my name is #{merchant.first_name}, " : ''
			        custom_welcome = "Hi there, " + first_name + "how can I assist you today? If you're looking to send a payment, simply reply with the amount. Ex. +10 #donut"
			        custom_welcome = merchant.custom_welcome unless merchant.custom_welcome.blank?
					send_response(23, params[:to], params[:msisdn], custom_welcome)
				end 

				send_wrong_format_message(params[:to], params[:msisdn]) if amount_array[1]

			else
				save_inbound_text(request.query_string, msg_code = 5)	# user exist, but not a payment message...save in messages
				# until nexmo can give use concatenated messages..i think they do now (06/14/14) #remove			
				send_wrong_format_message(params[:to], params[:msisdn]) if amount_array[1]		
			end
		rescue StandardError => err
			logger.error err.message
  			err.backtrace.each { |line| logger.error line }
			# notify us something went wrong
		end
	end

	def check_for_tag(amount_array, merchant_id)
		tag = nil		
    	tag = Hashtag.where('user_id = ? and lower(tag) = ?', merchant_id, amount_array[2].downcase) if amount_array[2]
    	tag_amount = (tag && tag.amount) ? tag.amount : nil
    	tag_precedent = (tag && tag.is_precedent) ? true : false
    	return amount_array[0], amount_array[1], tag, tag_amount, tag_precedent
	end

	def process_payment(amount_array, merchant, user, text, request)
    	saved_message = save_inbound_text(request.query_string, msg_code = 1)
    	if not_repeating_payment?(user.id, text)
			customer_txn_id = Transaction.charge_customer_card(amount, merchant, user, text)
			saved_message.update(transaction_id: customer_txn_id) if saved_message && saved_message.id.present?	# Save transaction id
		end
		# see number 20. Used for payment system outage
		# send_response(20, params[:to], params[:msisdn], "Thank you for sending a payment with rhombus. We're currently experiencing a system outage. We will notify you once the outage is resolved. Thanks!")
	end


	def not_repeating_payment?(id, text)
		# if necessary, you could modify the query to return a text sent to a specific merchant..so add user_id_to
		last_messages = Message.where("user_id = ? and created_at >= ?", id, Time.now.utc - 5.minutes).order(created_at: :desc)[1..-1]
		return true if last_messages == nil
		last_messages.each do |m|
			return false if m.text.strip == text
		end
 		return true
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
		
		# also notify merchant via PUSH and email

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
		#send message over limit
		# save in messages and send a response
		save_inbound_text(request.query_string, msg_code = 2)
		# notify user
		send_response(12, params[:to], params[:msisdn], "Sorry, we are unable to make payments above 15,000 dollars. But you can send in smaller amounts. Thanks!")
		
		# also notify merchant via PUSH and email

		return false
	end

	def is_payment_dollar?(text)
		amount = get_number(text)
		dollar_present = text.chr == "$" ? "$" : false
		return to_cents(amount), dollar_present if dollar_present && is_number?(amount)
		return false, dollar_present
	end


	def is_payment_plus?(text)
		t = text.scan(/[+#]\S+/)
		amt = false
		tag = false
		plus_present = false
		t.each do |i|
			if i[0] == "+" && !amt
				plus_present = "+"
				amt = to_cents(i[1..-1]) if is_number?(i[1..-1])
			elsif i[0] == "#" && !tag
				tag = i
			end
			break if amt && tag
		end
		return amt, plus_present, tag
	end


	def check_for_payment(text)
		amount_array = is_payment_dollar?(text)
		amount_plus_array = is_payment_plus?(text)
		if amount_array[0] || amount_array[1]
			amount_array[2] = amount_plus_array[2]
			return amount_array
		end
		return amount_plus_array		
	end

	def send_wrong_format_message(to, from)
		# this is the last msg_code assigned 08/19/15
		send_response(25, to, from, 'We noticed you tried to send a payment. Please resend it in this format. Ex. +5 #CheeseBurgers')
	end


	def deprecation_warning(to, from)
		send_response(24, to, from, "We're improving your payment experience on Rhombus by replacing the $ sign with a + tag. Ex. You can now text +10 instead of $10.")
		send_response(24, to, from, 'With the + tag, you can now place the amount anywhere in the message. Ex. "cheese burgers +8 yay!", instead of "$8 cheese burgers')
		send_response(24, to, from, "Btw, hashtags are awesome! You can now use hashtags to specify the item you're paying for or the campaign you're donating towards. Ex. +5 #CheeseBurgers")
		send_response(24, to, from, "This helps your local business know exactly what you are paying for!")
	end


	def get_number(text)
		return (text.split(" ", 2).first[1..-1])
	end


	def is_number?(var)
		#bad way to rescue
  	   	true if Float(var) rescue false
	end


	def is_signup?(text)
		words = ['signup', 'sign-up', "#signup", "#sign-up", 'give', "#give", 'pay', "#pay", 'buy', '#buy', 'donate', "#donate"]
		return true if words.include? text.downcase.gsub(/\s+/, "")  
		return false
	end


	def to_cents(var)
		return ((var.to_f.round(2).abs)*100).round
	end


	def send_response(msg_code, to, from, message) 
		@message = Message.new 				
		@message.send_and_save_message(msg_code, to, from, message)
   		RealtimeStreamService.send_message_via_number(from, to, message, @message.created_at, true)		# Send to merchant's messaging channel
	end

	
	def save_inbound_text(query, msg_code, transaction_id = 0)						# if not for payment, transaction_id = 0
		query_hash = Rack::Utils.parse_nested_query(query)      					# deal with some weird params from nexmo
		@message = Message.new

		# review - save_text returns id already...can i still get all the property without breaking into two lines
		# plus returning @message doesnt guarantee that it actually saved 
		# return value used in 2 places
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
		rescue StandardError => err
			# if somehow the message id doesnt exist
			@message = Message.new

			# i removed client ref here...why???
			@message.save_text(from: query_hash["to"], network_code: query_hash['network-code'], messageId: query_hash['messageId'], 
				to: query_hash["msisdn"], status_delivery: query_hash["status"], err_code: query_hash['err-code'], message_price: query_hash["price"], 
				scts: query_hash['scts'], message_timestamp: query_hash["message-timestamp"], message_code: 8)
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