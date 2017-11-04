
# TASK Last

desc "create customer and contacts"
task :create_customer_and_contacts => :environment do

  Message.in_batches.each do |messages|
    puts "Going to update #{messages.count} messages"
    ActiveRecord::Base.transaction do  
      orphaned_count = 0
      messages.each do |m|
        puts "\n"
        re = true

        # Merchant must exists
        u = User.find_by(id: m.user_id)
        # if merchant
        if u.try(:is_merchant?)
          cus = User.find_by(id: m.user_id_to) # find user
          re = cus ? MerchantCustomer.add_or_update_merchant_customer(u, cus) : MerchantContact.add_or_update_merchant_contact(u.id, m.to, 'phone_number')
        else          
          u = User.find_by(id: m.user_id_to)
          if u.try(:is_merchant?)
            cus = User.find_by(id: m.user_id)
            re = cus ? MerchantCustomer.add_or_update_merchant_customer(u, cus) : MerchantContact.add_or_update_merchant_contact(u.id, m.from, 'phone_number')
          else 
            # else orphaned message  
            puts "this message is orphaned. id #{m.id} => #{m.text}"
            orphaned_count = orphaned_count + 1
            puts "#{orphaned_count} so far"
          end          
        end

        raise StandardError unless re
        puts "moving on... \n"
      end
    end
    sleep(2)
  end

end