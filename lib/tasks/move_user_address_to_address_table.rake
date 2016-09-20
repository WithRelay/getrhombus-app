
# run after migrations since we need the address
# then run the migration below to remove the unwanted columns afterwards.

#  Dont remove stripe_livemode since it is used by customers and now merchants will use it too
#  def change
#    remove_column :users, :zip_code
#  end


desc "move stripe connect details in users to stripe cred table"
task :move_stripe_connect_details_to_stripe_cred => :environment do

  User.all.each do |u|
    Address.create(street_address: u.street_address, city: u.city, state_province: u.state_province, 
                    country: u.country, postal_code: u.zip_code, addressable_id: u.id)
  end
end