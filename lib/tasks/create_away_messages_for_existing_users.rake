

# TASK 1

# run after all migrations to create alerts for users
# SELECT * FROM users where business_phone = '' and user_level = 1
desc "Create away message"
task :create_away_message_for_existing_teams => :environment do
  users = User.where(user_level: 1)
  puts "Going to update #{users.count} users"
  
  ActiveRecord::Base.transaction do
    users.each do |user|
      puts user.email
      AwayMessage.find_or_create_by!(user_id: user.id) { |am| am.response = "We're away at the moment and will get back to you when we return :)." }
      puts "created \n"
    end
  end
end
