
desc "notify users of merchant number change"
task :number_change => :environment do

	require 'uri'	
	def send_message(msg, to)
		api_key: '<redacted_api_key>'
		api_secret: '<redacted_api_secret>'
		from: '<redacted_phone_number>'
		# encode the nexmo uri
		uri = URI.encode_www_form([["api_key",api_key], ["api_secret", api_secret], ["from", from], ["to", to], ["text", msg]])	
		response = HTTParty.post('https://rest.nexmo.com/sms/json?'+ uri, :headers => {"Content-Type" => "application/x-www-form-urlencoded"} )
		if response.code == 200 and response["messages"].first["status"] == "0"		
			puts "sent to =>	#{response['messages'].first['to']}"
		else			
			puts "not sent to =>	#{response['messages'].first['to']}"
		end
	end

	
	message = "Dear JHDC Member, we want to sincerely apologize for the difficulty in processing your text payments to JHDC during the week. We've resolved the issue by switching to a toll free number - <redacted_phone_number>, which has a higher priority and capacity with all mobile networks. We would like to emphasize that if you didn't receive a confirmation for any text you sent during the week, your credit/debit card account wasn't charged because your mobile network didn't deliver the message to us. Please save/update this number in your phone contacts, and resend any text payment as needed. Again we are sorry for any inconvenience, and thank you for using Rhombus."

	sql = ActiveRecord::Base.send(:sanitize_sql_array, 
				["SELECT users.first_name as first_name, users.card_name as card_name, t1.phone, users.instrument_uri FROM 
					( select messages.from as phone from messages where messages.to = ?
    				  union
					  select messages.to as phone from messages where messages.from = ?
					) t1
					inner join users on t1.phone = users.phone_number", "<redacted_phone_number>", '<redacted_phone_number>'])

	results = Message.connection.execute(sql)
	results.each do |r|
		send_message(message, r[2])
	end

=begin	
	results.each do |r|
		name = r[0] ? r[0].capitalize : r[1] ? r[1].split(" ")[0].capitalize : 'there'
		send_message("Hi " + name + message, r[2])
		if !r[3]
			send_message("Also, you currently don't have a payment info on your profile. You can log in at www.getrhombus.com/signin and update your profile. Then you can make a payment by texting the number above. Ex: $500 tithe", r[2])
		end
	end
=end

end

# Schuamburg church number 12/03/15
=begin
	numbers = [ "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>",
				"<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>",
				"<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>",
				"<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>",
				"<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>",
				"<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>",
				"<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>",
				"<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>",
				"<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>",
				"<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>",
				"<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>",
				"<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>",
				"<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>",
				"<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>" ]
=end