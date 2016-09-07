
# run after migrations since we need the referrer tabls
# then run the migration below to remove the unwanted columns afterwards.

#  def change
#    remove_column :users, :referrer_num
#  end


desc "move referrer number from users to referrer table"
task :move_referrer_num_to_referrer_table => :environment do

  User.all.each do |u|
    if u.referrer_num.present?
      if ref = User.find_by(rhombus_number: u.referrer_num)
        Referrrer.save_referrer_with_id(ref.id, u.id)
      end
    end
  end


  # change all bitly links to use ids

  # Stripe default referral for Stripe
  Referrrer.create_stripe_default  
end