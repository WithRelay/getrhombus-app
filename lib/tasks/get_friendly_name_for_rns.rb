

desc "get friendly names for rhombus numbers"
task :get_friendly_name_for_rns => :environment do

  User.where(user_level: 1).each do |t|
  	t.update(friendly_name: t.rhombus_number)
  end
end
