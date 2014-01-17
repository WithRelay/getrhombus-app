class Message < ActiveRecord::Base
	require 'uri'


	def send_text_message
		url = URI.encode_www_form([["api_key", "0ed6ecb8"],
					["api_secret", "b4f769d8"],
					["from", "<redacted_phone_number>"],
					["to", "<redacted_phone_number>"],
					["text", "are u eddy?"],

				])
		@response = HTTParty.post('https://rest.nexmo.com/sms/json?'+ url, :headers => {"Content-Type" => "application/x-www-form-urlencoded"} )
	end

	def send_signup_text
		url = URI.encode_www_form([["api_key", "0ed6ecb8"],
					["api_secret", "b4f769d8"],
					["from", "<redacted_phone_number>"],
					["to", "<redacted_phone_number>"],
					["text", "www.getrhombus.com/signup"],

				])
		@response = HTTParty.post('https://rest.nexmo.com/sms/json?'+ url, :headers => {"Content-Type" => "application/x-www-form-urlencoded"} )
	end

	def save_text_from_user
		@message = Message.new
		@message.text = params[:text]
		@message.save
		render status: 200

	end

end
