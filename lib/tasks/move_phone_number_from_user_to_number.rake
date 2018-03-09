
# 1. run task first

desc 'Move all phone numbers from User to Number table'
task move_phone_number_from_user_to_number: :environment do
  provider = 'nexmo'
  
  User.find_each do |u|
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

