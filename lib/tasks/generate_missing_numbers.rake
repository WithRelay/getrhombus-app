
  desc "generate_missing_numbers"
  task :generate_missing_numbers => :environment do
    require 'csv'    

    user_ids = [7732, 7889, 7890, 7891, 7892, 7893]
    lists = List.where(user_id: user_ids, segment: nil).pluck(:id)
    puts lists.inspect
    uls = UserList.where(list_id: lists, customer_contact_type: 'MerchantContact').pluck(:customer_contact_id)
    puts uls.inspect

    if uls.present?
      numbers = MerchantContact.joins("LEFT JOIN messages ON merchant_contacts.uid = messages.to")
                  .where("merchant_contacts.id in (#{uls.join(',')}) and merchant_contacts.is_customer = 0 and messages.user_id in (#{user_ids.join(',')}) and messages.to is null")
                  .pluck(:uid)
    
      csv_string = CSV.generate do |csv|
        csv << ['Phone Number']
        numbers.each { |number| csv << [number] }
      end
      
      attachment_hash = { attachments: [ { content: Base64.encode64(csv_string),
                                            name: "file.csv",
                                            type: "text/csv" } ] }

      EmailingService.email_to_platform("See Attached for Numbers not texted", 'RMG Data', attachment_hash)
    end
    
  end
