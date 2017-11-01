

# TASK 2

desc "get friendly names for rhombus numbers"
task :get_friendly_name_for_rns => :environment do

  ActiveRecord::Base.transaction do
    User.where(user_level: 1).each do |user|
      puts user.email
      re = TextingService.number_lookup(user.rhombus_number)
      if re.try(:third).present?
        puts "#{user.rhombus_number} => #{re[2]}"
    	  user.update!(friendly_name: re[2]) 
      end
    end
  end
end
