
# run after migration for user_id_to is changed to user_id
# run before you remove user_id and user_id_from

# Ensure that messages table have the most current number for customers who changed their
# numbers. This wasn't done before and could be the case.

# Do this for merchants whose rhombus_number is not null 
# We don't want to overwrite the messages data to null because they might come back
# We would lose their message history. We have a list of their numbers before it was removed.
# So we can go back.

desc "Update all customer phone number in DB based on user id and vice versa"
task :update_customer_number_data => :environment do

  Message.all.each do |m|

    u = User.where(id: m['user_id'])
    if u.present? && u.user_level == 0
      m.from = u.phone_number 
    elsif u.present? && u.user_level == 1 && u.rhombus_number.present?
      m.from = u.rhombus_number 
    end

    u = User.where(id: m['user_id_to'])
    if u.present? && u.user_level == 0
      m.to = u.phone_number 
    elsif u.present? && u.user_level == 1 && u.rhombus_number.present?
      m.to = u.rhombus_number 
    end     
    
    m.save

  end
end