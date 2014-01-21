class Message < ActiveRecord::Base
	require 'uri'
	
	# For sending any text message
	def nexmo_send_text_message(number)
		url = URI.encode_www_form([["api_key", "0ed6ecb8"],
					["api_secret", "b4f769d8"],
					["from", "<redacted_phone_number>"],
					["to", number],
					["text", "we sent payment"],

				])
		response = HTTParty.post('https://rest.nexmo.com/sms/json?'+ url, :headers => {"Content-Type" => "application/x-www-form-urlencoded"} )
		###### Check response
		###### Then save fields
	end

	# For signing up users
	def nexmo_send_signup_text(number)
		url = URI.encode_www_form([["api_key", "0ed6ecb8"],
					["api_secret", "b4f769d8"],
					["from", "<redacted_phone_number>"],
					["to", number],
					["text", "www.getrhombus.com/signup?num=" + "#{number}"],

				])
		response = HTTParty.post('https://rest.nexmo.com/sms/json?'+ url, :headers => {"Content-Type" => "application/x-www-form-urlencoded"} )
		##### Check response
	end

	# Search and buy a number to assign to a new merchant
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
