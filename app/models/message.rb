class Message < ActiveRecord::Base
	
	require 'uri'
	api_key: '<redacted_api_key>'
	api_secret: '<redacted_api_secret>'

	belongs_to :transaction
	#belongs_to :user, counter_cache: true
	
	# For sending all text messages
	def nexmo_send_text_message(from, to, message)
		
		# save the outbound message
		@message = Message.new 											
		client_ref = @message.save_text(from: from, to: to, type: "text", text: message, status_report_req: 1, message_type: 1)
		
		# encode the nexmo uri
		uri = URI.encode_www_form([["api_key", api_key], ["api_secret", api_secret], ["from", from], ["to", to], 
			["text", message], ["status-report-req", "1"], ["client-ref", client_ref]])		
		
		# call nexmo api
		response = HTTParty.post('https://rest.nexmo.com/sms/json?'+ uri, :headers => {"Content-Type" => "application/x-www-form-urlencoded"} )
		
		# check response
		if response.code == 200 and response["messages"].first["status"] == "0"
		
			# Fetch the saved outbound message and attach nexmo's response to it
			@message = Message.find_by(id: response['messages'].first["client-ref"])
			@message.save_text(status: response['messages'].first['status'], messageId: response['messages'].first['messageId'],
				client_ref: response['messages'].first['client-ref'], message_price: response['messages'].first['message-price'], 
				network_code: response['messages'].first['network'])
		else
		
			# Notify marketplace owner of failure
			Notification.text_failure_notification(response["messages"].first).deliver
		end
	end


	def nexmo_search_and_buy_number(country)

		# search for a number on nexmo
		response = HTTParty.get('https://rest.nexmo.com/number/search/'+ api_key + "/" + api_secret + "/" + country + "?features=SMS,VOICE&size=1")
		
		# check the response
		if response.code == 200 and response["numbers"].first["msisdn"] != ""
			msisdn = response["numbers"].first["msisdn"]

			# buy number
			response = HTTParty.post('https://rest.nexmo.com/number/buy/'+ api_key + "/" + api_secret + "/" + country + "/" + msisdn)
			
			# check response
			if response.code == 200

				# Save number to merchant
				msisdn
			else

				# Notify marketplace owner of failure
				Notification.text_failure_notification(response["messages"].first).deliver
				#return response
			end
		else
			# Notify marketplace owner of failure
			Notification.text_failure_notification(response["messages"].first).deliver
			#return response
		end
	end

	
	# for saving any text received or sent
	def save_text(options = {})

		# 20 fields
		self.text = options[:text] if options[:text]

		if options[:from]
			# Attached the phone number and user id
			self.from = options[:from] 
			self.user_id_from = User.find_by(phone_number: "#{options[:from]}").id rescue 0
		end

		if options[:to]
			# Attached the phone number and user id
			self.to = options[:to] 
			self.user_id_to =  User.find_by(phone_number: "#{options[:to]}").id rescue 0
		end
		
		self.network_code = options[:network_code] if options[:network_code]
		self.messageId = options[:messageId] if options[:messageId]
		self.message_timestamp = options[:message_timestamp] if options[:message_timestamp]
		self.type = options[:type] if options[:type]
		self.status_report_req = options[:status_report_req] if options[:status_report_req]
		self.message_type = options[:message_type] if options[:message_type]
		self.message_price = options[:message_price] if options[:message_price]
		self.scts = options[:scts] if options[:scts]
		self.client_ref = options[:client_ref] if options[:client_ref]
		self.status = options[:status] if options[:status]
		self.status_delivery = options[:status_delivery] if options[:status_delivery]
		self.err_code = options[:err_code] if options[:err_code]
		self.error_text = options[:error_text] if options[:error_text]
		self.message_code = options[:message_code] if options[:message_code]		
		self.transaction_id = options[:transaction_id] if options[:transaction_id]
		self.save
		return self.id
		#if @message.save
		#	return 200
		#else
			#return 500
		#end
		#return options[:sure]
	end

end
