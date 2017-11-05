
# TASK 13

desc "create customer and contacts"
task :create_customer_and_contacts => :environment do

  ActiveRecord::Base.transaction do  
    orphaned_count = 0
    Message.find_each do |m|  
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

      if re
        re.update!(created_at: m.created_at, updated_at: m.updated_at) if re.try(:id).present?
      else
        raise StandardError 
      end
      puts "moving on... \n"
    end
    puts "#{orphaned_count} TOTAL"
  end

end