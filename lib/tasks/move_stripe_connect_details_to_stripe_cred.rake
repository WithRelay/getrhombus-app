
# TASK 6

# 1. run migrations since we need the stripe cred table 

desc "move stripe connect details in users to standalone stripe cred table"
task :move_stripe_connect_details_to_standalone_stripe_cred => :environment do
  ActiveRecord::Base.transaction do
    count = 0
    User.where(user_level: 1).each do |u|
      puts "\n"
      count = count + 1
      puts "#{count}"
      if u.stripe_access_token.present?
        puts "Update #{u.email}"
        s = StandaloneStripeCred.create!(secret: u.stripe_access_token, publishable_key: u.stripe_publishable_key,
                                      account_id: u.uid, scope: u.stripe_scope, refresh_token: u.stripe_refresh_token,
                                      user_id: u.id, livemode: u.livemode, transaction_fee_id: 2)
        puts "#{s.id}"
      end
      puts "Moving on \n"
    end
  end
end

# Then
# 2. run the migration below to remove the unwanted columns afterwards.

#  Dont remove stripe_livemode since it is used by customers and now merchants will use it too for their cards
#  def change
#     remove_column :users, :provider
#     remove_column :users, :stripe_scope
#     remove_column :users, :stripe_refresh_token
#     remove_column :users, :stripe_publishable_key
#     remove_column :users, :stripe_access_token
#     remove_column :users, :uid
#  end
