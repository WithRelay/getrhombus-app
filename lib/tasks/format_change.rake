
desc "notify users to format change"
task :format_change => :environment do

	require 'uri'	
	api_key: '<redacted_api_key>'
	api_secret: '<redacted_api_secret>'
	from: '<redacted_phone_number>'
	
	# message = "Hi there, pls sign in and update your card info on Rhombus getrhombus.com/signin - Also do save this number as NWA updated rhombus number. Then you can give your tithe (or offering) anytime by simply texting '$100, tithe'. Thanks! :)"
	
	numbers = [ "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", '<redacted_phone_number>', '<redacted_phone_number>', 
		        "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", 
		        "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", 
		        "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", 
		        "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>",
		        "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>",
		        "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>",
		        "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>" ]

    # RCCGNA # <redacted_phone_number>
	# numbers = ["<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>"]
	
	# Salvation center # <redacted_phone_number>
	# numbers = ["<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>"]

	numbers.each do |to|
		# encode the nexmo uri
		uri = URI.encode_www_form([["api_key",api_key], ["api_secret", api_secret], ["from", from], ["to", to], 
			["text", message]])		
		# call nexmo api
		response = HTTParty.post('https://rest.nexmo.com/sms/json?'+ uri, :headers => {"Content-Type" => "application/x-www-form-urlencoded"} )
		
		# check response
		if response.code == 200 and response["messages"].first["status"] == "0"		
			puts "sent to =>	#{response['messages'].first['to']}"
		else			
			puts "not sent to =>	#{response['messages'].first['to']}"
		end
	end
end