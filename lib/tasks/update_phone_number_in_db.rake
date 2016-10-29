
# run after migrations

# Ensure that messages table have the most current number for customers who changed their
# numbers. This wasn't done before and could be the case.

# No need to remove user_id, user_id_to fields, we will need it 
  # def change
    #remove_column :messages, :user_id
    #remove_column :messages, :user_id_to

  # end
# 1. if a merchant comes back and we need to update their message history....
# 2. we need it to pull messages. You can't use phone_number only cos if someone else signs up with your number
# they will see your history.



# Do this for merchants whose rhombus_number is not null 
# We don't want to overwrite the messages data to null because those without a rhombus_number
# might come back.
# We would lose their message history. We have a list of their numbers before it was removed 
# or we can just use their user_id to do the update. So we can go back!

=begin
 
 # some cleanups
  # In the early days we had user_id and user_id_to as 0 if the phone_number or
  # rhombus number don't exist
  # this is an attempt to fix it but it might not catch all
  select * from messages where used_id_from = 0 

  select * from users where phone_number
in (select rhombus_number from users)
  
=end

desc "Update all customer phone number in DB based on user id and vice versa"
task :update_customer_number_data => :environment do

  # update messages
  Message.all.each do |m|
    # none payment messages
    m.transaction_id = nil if m.transaction_id == 0

    # update each message using user_ids to most current user details 
    # if user_id_from_exists
    
    # you could use from and to fields to do the reverse and set user_ids, but 
    # 1. you run the risk of reassigning messages to others if someone else now has the number (we didnt update
    # message history when you change number in the past. Now we do). Very minimal risk prior to v1.5.
    # 2. Prior to v1.5, some customers signed up with rhombus number as phone number. DB data was checked and
    # there were 2 results. Rows were deleted.
    # 3. These doesnt clean up orphans completely since not all users sign up and some rhombus number were deleted.

    # In the early days we had set user_id and user_id_to to 0
    # if user doesnt exists based on phone or rhombus number, but set to nil
    
    if u = User.find_by(id: m.user_id) 
      if u.user_level == 0
        m.from = u.phone_number 
      elsif u.user_level == 1 && u.rhombus_number.present?
        m.from = u.rhombus_number 
      end
    elsif u = User.find_by(phone_number: m.from)
      m.user_id = u.id 
    elsif u = User.find_by(rhombus_number: m.from)
      m.user_id = u.id 
    else
      m.user_id = nil
    end

    if u = User.find_by(id: m.user_id_to) 
      if u.user_level == 0
        m.to = u.phone_number 
      elsif u.user_level == 1 && u.rhombus_number.present?
        m.to = u.rhombus_number 
      end
    elsif u = User.find_by(phone_number: m.to)
      m.user_id_to = u.id 
    elsif u = User.find_by(rhombus_number: m.to)
      m.user_id_to = u.id 
    else
      m.user_id_to = nil
    end   

    m.save
  end

end