
  desc "generate_missing_numbers"
  task :generate_missing_numbers => :environment do
    require 'csv'    

    user_ids = [7732, 7889, 7890, 7891, 7892, 7893]
    #lists = List.where(user_id: user_ids, segment: nil).pluck(:id)
    #uls = UserList.where(list_id: lists, customer_contact_type: 'MerchantContact').pluck(:customer_contact_id)

    #if uls.present?
      #numbers = MerchantContact.joins("LEFT JOIN messages ON merchant_contacts.uid = messages.to")
      #            .where("merchant_contacts.id in (#{uls.join(',')}) and merchant_contacts.is_customer = 0 and messages.user_id in (#{user_ids.join(',')}) and messages.id is null")
      #            .pluck(:uid)


      numbers = MerchantContact.find_by_sql("select uid from merchant_contacts where merchant_id in (#{user_ids.join(',')}) 
                                          and is_customer = 0 
                      and uid not in 
                      ( 
                        select `to` as uid from messages where user_id in (#{user_ids.join(',')}) 
                        UNION ALL
                        select `from` as uid from messages where user_id_to in (#{user_ids.join(',')})
                      )")

      puts numbers.inspect
    
      csv_string = CSV.generate do |csv|
        csv << ['Phone Number']
        numbers.each { |number| csv << [number.uid] }
      end
      
      attachment_hash = { attachments: [ { content: Base64.encode64(csv_string),
                                            name: "file.csv",
                                            type: "text/csv" } ] }

      EmailingService.email_to_platform("See Attached for Numbers not texted", 'RMG Data', attachment_hash)
    #end
    
  end
