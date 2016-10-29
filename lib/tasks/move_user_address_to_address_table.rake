
# run after migrations since we need the address
# then run the migration below to remove the unwanted columns afterwards.

#  remove columns
=begin
  def change
    remove_column :users, :zip_code
  	remove_column :users, :street_address
  	remove_column :users, :city
  	remove_column :users, :state_province
  	remove_column :users, :country
  end

 # some cleanup
 # null or nothing	
	select * from users where length(country) = 0
	select * from users where length(country) = 1
	select * from users where country is null	
	select * from users where user_level = 0 
	and country = "" # is not null
=end


desc "move address in user table to address table"
task :move_user_address_to_address_table => :environment do

  User.where(user_level: 1).each do |u|

  	# move only merchants even if some user info is incomplete
  	# we currently don't need customer address
  	if u.street_address.present? || u.city.present? || u.state_province.present? || u.country.present? || u.zip_code.present?
    	
    	Address.create(street_address: u.street_address, city: u.city, state_province: u.state_province, 
                    country: u.country, postal_code: u.zip_code, addressable_id: u.id)
	end
  end
end