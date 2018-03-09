desc 'Move all phone numbers from User to Number table'
task move_phone_number_from_user_to_number: :environment do
  User.find_each do |user|
    begin
      user.numbers.create(number: user.phone_number, default: true)
      puts "Success to move phone number from user: #{user.email} to number"
    rescue Exception => e
      puts "Failed to move phone number from user: #{user.id} to number"
      next
    end
  end
end
