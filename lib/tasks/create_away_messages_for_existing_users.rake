




### TODOSSSSSSSSSS **********************
# 1. FIX DUPLICATE IDS IN MESSAGES
# 2. COPY OUT REFUNDS ID SO I CAN UPDATE AFTER RELEASE
# 3. UPDATE PLATFORM EMAIL 
# 4. Get a production number


# TASK 1. Tested

# run after all migrations to create alerts for users
# SELECT * FROM users where business_phone = '' and user_level = 1
desc "Create away message"
task :create_away_message_for_existing_teams => :environment do
  users = User.where(user_level: 1)
  puts "Going to update #{users.count} users"
  
  ActiveRecord::Base.transaction do
    users.each do |user|
      puts "\n"
      puts user.email
      AwayMessage.find_or_create_by!(user_id: user.id) { |am| am.response = "We're away at the moment and will get back to you when we return :)." }
      puts "created \n"
    end
  end
end




desc "switch rails logger to stdout"
task :verbose => [:environment] do
  Rails.logger = Logger.new(STDOUT)
end

desc "switch rails logger log level to debug"
task :debug => [:environment, :verbose] do
  Rails.logger.level = Logger::DEBUG
end