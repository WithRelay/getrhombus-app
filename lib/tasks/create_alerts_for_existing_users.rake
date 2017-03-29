
# run after all migrations to create alerts for users
# SELECT * FROM users where business_phone = '' and user_level = 1
desc "Create alerts and away message, update friendly name for every existing teams"
task :create_alerts_and_away_message_friendly_name_for_teams => :environment do

  User.where(user_level: 1).each do |t|
    Alert.create(user_id: t.id)
    AwayMessage.create(user_id: t.id, response: "We're away at the moment and will get back to you when we return :).")
    t.update(friendly_name: t.rhombus_number)
  end
end
