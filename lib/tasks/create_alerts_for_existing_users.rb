
# run after all migrations to create alerts for users

desc "Create alerts for every user"
task :create_alerts_for_teams => :environment do
  
  User.where(user_level: 1).each do |t|
    Alert.create(user_id: t.id, sms_number: t.org_phone)
  end
end