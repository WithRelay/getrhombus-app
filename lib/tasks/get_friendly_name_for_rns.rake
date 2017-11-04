

# TASK 2. Tested

desc "get friendly names for rhombus numbers"
task :get_friendly_name_for_rns => :environment do
  users = User.where(user_level: 1)

  ActiveRecord::Base.transaction do
    users.each_with_index do |user, i|
      puts "\n"
      puts user.email
      if user.rhombus_number.present?
        re = TextingService.number_lookup(user.rhombus_number)
        if re.try(:third).present?
          puts "#{user.rhombus_number} => #{re[2]}"
      	  user.update!(rn_friendly_name: re[2]) 
        end
      end
    end
  end
end
