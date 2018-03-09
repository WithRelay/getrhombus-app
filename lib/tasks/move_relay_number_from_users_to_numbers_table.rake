
# 1. run task first

desc 'Move all relay numbers from Users to Numbers table'
task move_relay_number_from_users_to_numbers_table: :environment do
  provider = 'nexmo'
  
  User.where(user_level: 1).each do |u|
    provider = 'nexmo'

    if u.rn_type.present?
      provider = 'twilio' 
    elsif u.fn_subscriber_id.present?
      provider = 'fibernetics'
    end

    u.numbers.create(number: u.rhombus_number, friendly_name: u.rn_friendly_name, type: u.rn_type, country: u.rn_country, 
                      default: true, provider: provider, fibernetics_subscriber_id: u.fn_subscriber_id)
  end
end

# Then
# 2. run migration to remove columns from users table
#  def change
#    remove_column :users, :rhombus_number
#    remove_column :users, :rn_friendly_name
#    remove_column :users, :rn_type
#    remove_column :users, :rn_country
#    remove_column :users, :fn_subscriber_id
#  end

