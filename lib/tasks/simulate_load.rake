
desc "test site messaging load"
task :test_load => :environment do
	require 'net/http'
	count = 1
	500.times do
		result = Net::HTTP.get(URI.parse('https://www.getrhombus.com/receive_text_message?text=$6,500-' + count.to_s + "-" + Time.zone.now.strftime("%I:%M:%S%p").to_s + '&msisdn: '<redacted_phone_number>'&to: '<redacted_phone_number>'))
		puts count, Time.zone.now.strftime("%I:%M:%S%p")
		count = count + 1
	end
end

desc "test site messaging load"
task :test_load_2 => :environment do
	require 'net/http'
	count = 1
	200.times do
		result = Net::HTTP.get(URI.parse('https://www.getrhombus.com/receive_text_message?text=$6,200-' + count.to_s + "-" + Time.zone.now.strftime("%I:%M:%S%p").to_s + '&msisdn: '<redacted_phone_number>'&to: '<redacted_phone_number>'))
		puts count, Time.zone.now.strftime("%I:%M:%S%p")
		count = count + 1
	end
end

desc "test site messaging load"
task :test_load_3 => :environment do
	require 'net/http'
	count = 1
	150.times do
		result = Net::HTTP.get(URI.parse('https://www.getrhombus.com/receive_text_message?text=$6,150-' + count.to_s + "-" + Time.zone.now.strftime("%I:%M:%S%p").to_s + '&msisdn: '<redacted_phone_number>'&to: '<redacted_phone_number>'))
		puts count, Time.zone.now.strftime("%I:%M:%S%p")
		count = count + 1
	end
end