### Task no longer usable because of multi-numbers
# TASK 5. Tested

# 1. run after migrations since we need the referrer tables

desc "move referrer number from users to referrer table"
task :move_referrer_num_to_referrer_table => :environment do
  count = 0
  ActiveRecord::Base.transaction do
    User.where(user_level: 0).each do |user|
      puts "\n"
      puts user.email

      if user.referrer_num.present? 
        puts "#{user.referrer_num}"
        referrer = User.find_by(rhombus_number: user.referrer_num)  
        if referrer
          count = count + 1
          puts "count => #{count}"
          puts "Referrer: #{referrer.email}"
          Referrer.save_referrer_with_uid(referrer.relay_uid, user.id)
        end
      end

      puts "Moving on \n"
    end
  end

end

# Then
# 2. run update migrations
  #  def change
  #    remove_column :users, :referrer_num
  #  end


