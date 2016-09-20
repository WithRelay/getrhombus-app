
# run after migrations since we need the stripe cred table
# then run the migration below to remove the unwanted columns afterwards.

#  Dont remove stripe_livemode since it is used by customers and now merchants will use it too
#  def change
#     remove_column :users, :provider
#     remove_column :users, :stripe_scope
#     remove_column :users, :stripe_refresh_token
#     remove_column :users, :stripe_publishable_key
#     remove_column :users, :stripe_access_token
#     remove_column :users, :uid
#  end


desc "move stripe connect details in users to stripe cred table"
task :move_stripe_connect_details_to_stripe_cred => :environment do

  User.where("user_level = ? and stripe_access_token is not null", 1).each do |u|
    StripeCred.create(secret: u.stripe_access_token, publishable_key: u.stripe_publishable_key,
                        uid: u.uid, scope: u.stripe_scope, refresh_token: u.stripe_refresh_token,
                        user_id: u.id, livemode: u.livemode, uid_type: 'standalone')
  end
end