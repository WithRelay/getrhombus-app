desc "remove card and bank data"
task :clean_data => :environment do
	u = User.all
	u.each do |p|

		p.last_four = nil
		p.expiration_month = nil
		p.expiration_year = nil
		p.zip_code = nil
		p.card_name = nil
		p.card_type = nil
		p.customer_uri = nil
		p.instrument_uri = nil

		p.routing_number = nil
		p.account_name = nil
		p.account_type = nil
		p.account_number = nil
		
		p.save
	end

end