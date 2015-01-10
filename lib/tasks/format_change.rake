
desc "notify users to format change"
task :format_change => :environment do

	require 'uri'	
	api_key: '<redacted_api_key>'
	api_secret: '<redacted_api_secret>'	
    message = "Hi there! We've updated our payment format to make it more intuitive. You can now send a payment without including a comma! For example '$50 for offering' or '$20 2 cheese burgers and a diet coke'. Thank you for using Rhombus!"

=begin
	# RCCG NWA and WOLC
	from: '<redacted_phone_number>'
	numbers = [ "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", '<redacted_phone_number>', '<redacted_phone_number>', 
		        "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", 
		        "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", 
		        "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", 
		        "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>",
		        "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>",
		        "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>",
		        "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>" ]
=end

    # RCCGNA 
    # from: '<redacted_phone_number>'
	# numbers = ["<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>"]
	
	# Salvation center 
	# from: '<redacted_phone_number>'
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