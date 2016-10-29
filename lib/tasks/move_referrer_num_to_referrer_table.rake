
# run after migrations since we need the referrer tabls
# then run the migration below to remove the unwanted columns afterwards.

#  def change
#    remove_column :users, :referrer_num
#  end

  # Some cleanup might be necessary....check this again before we run this task
=begin
  # make sure all referrer_num exists since they are rhombus numbers
  select * from users where referrer_num 
  not in 
  (select rhombus_number from users) 
  #and user_level = 1

  # also run this
  # update all empty fields to null
  SET SQL_SAFE_UPDATES=0;
  UPDATE users
  SET referrer_num = null
  WHERE users.referrer_num = '';
  SET SQL_SAFE_UPDATES=1;

  # referrer_num should only be customers
  select * from users where referrer_num is not null 
  and user_level = 1
=end


desc "move referrer number from users to referrer table"
task :move_referrer_num_to_referrer_table => :environment do

  User.all.each do |u|
    # null if it wasn't set
    if u.referrer_num.present? 
      # will always exists...already checked and only customers have referrer_num set
      if ref = User.find_by(rhombus_number: u.referrer_num)  
        Referrer.save_referrer_with_id(ref.id, u.id)
      end
    end
  end

  # Stripe default referral for Stripe
  # for prod change in referrer.rb
  # ref.update_attribute(:link, "https://www.relay.com?referrer_uid=#{ref.uid}")
  Referrer.create_stripe_default  
end

