desc 'Move all phone numbers from User to Number table'
task move_phone_number_from_user_to_number: :environment do
  User.find_each do |user|
    user.numbers.create(number: user.phone_number, default: true)
  end
end
