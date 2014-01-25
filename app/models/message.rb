class Message < ActiveRecord::Base
	
	require 'uri'

	belongs_to :transaction
	#belongs_to :user, counter_cache: true
	
	# For sending any text message
	def nexmo_send_text_message(from, to, message)
		url = URI.encode_www_form([["api_key", "0ed6ecb8"],
					["api_secret", "b4f769d8"],
					["from", from],
					["to", to],
					["text", message],
					["status-report-req", "1"]
				])
		response = HTTParty.post('https://rest.nexmo.com/sms/json?'+ url, :headers => {"Content-Type" => "application/x-www-form-urlencoded"} )
		if response.code == 200 and response["messages"].first["status"] == 0
			###### Should have client-ref set i think
			###### Then save fields
			###### Check response then add delivery receipt logic around message id...not really
			return response
		else
			# Notify marketplace owner of failure
			return response
		end
	end

	# Search and buy a number to assign to a new merchant
	def nexmo_search_and_buy_number(country)
		api_key: '<redacted_api_key>'
		api_secret: '<redacted_api_secret>'
		response = HTTParty.get('https://rest.nexmo.com/number/search/'+ api_key + "/" + api_secret + "/" + country + "?features=SMS,VOICE&size=1")
		response["numbers"].first["msisdn"] = ""
		if response.code == 200 and response["numbers"].first["msisdn"] != ""
			msisdn = response["numbers"].first["msisdn"]
			# Buy number
			response = HTTParty.post('https://rest.nexmo.com/number/buy/'+ api_key + "/" + api_secret + "/" + country + "/" + msisdn)
			if response.code == 200
				# Save number to merchant
				msisdn
			else
				# Notify marketplace owner of failure
				return response
			end
		else
			# Notify marketplace owner of failure
			return response
		end
	end

	# For saving any text received or sent
	def save_text(options = {})
		self.text = options[:text] if options[:text]
		self.from = options[:from] if options[:from]
		self.to = options[:to] if options[:to]
		self.network_code = options[:network_code] if options[:network_code]
		self.messageId = options[:messageId] if options[:messageId]
		self.message_timestamp = options[:message_timestamp] if options[:message_timestamp]
		self.type = options[:type] if options[:type]
		#self.text = options[:text] if options[:text]
		#self.text = options[:text] if options[:text]
		#self.text = options[:text] if options[:text]
		#self.text = options[:text] if options[:text]
		#self.text = options[:text] if options[:text]
		#self.save
		#if @message.save
		#	return 200
		#else
			#return 500
		#end
		#return options[:sure]
	end

end
