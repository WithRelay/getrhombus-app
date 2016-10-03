
# run before any migrations since user_id_to is now user_id
# run after running conversations rake tasks

# Ensure that messages table have the most current number for customers who changed their
# numbers. This wasn't done before and could be the case.

# Add this migration

  # do i remove this? not sure i need to do this
#  def change
#    remove_column :messages, :user_id
#    remove_column :messages, :user_id_to
#  end

# Do this for merchants whose rhombus_number is not null 
# We don't want to overwrite the messages data to null because they might come back
# We would lose their message history. We have a list of their numbers before it was removed.
# So we can go back.

desc "Update all customer phone number in DB based on user id and vice versa"
task :update_customer_number_data => :environment do

  # update messages
  Message.all.each do |m|
    m.transaction_id = nil if m.transaction_id == 0

    u = User.where(id: m['user_id_from'])
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