
  desc "generate_missing_numbers"
  task :generate_missing_numbers => :environment do
    require 'csv'    

    user_ids = [7732, 7889, 7890, 7891, 7892, 7893]
    # < 704 to exclude lists uploaded for thursday. Deal with GOcampaigns 703, 705 later
    lists = List.where(user_id: user_ids, segment: nil).where("id < 700").pluck(:id)
    uls = UserList.where(list_id: lists, customer_contact_type: 'MerchantContact').pluck(:customer_contact_id)

    if uls.present?
      user_ids_str = user_ids.join(',')
      mcs = MerchantContact.find_by_sql("select merchant_contacts.uid from
                                              ( select `to` as uid from messages where user_id in (#{user_ids_str}) 
                                                  UNION
                                                select `from` as uid from messages where user_id_to in (#{user_ids_str}) 
                                              ) as t
                                                right join merchant_contacts on t.uid = merchant_contacts.uid
                                                where merchant_contacts.merchant_id in (#{user_ids_str}) and t.uid is null
                                                group by merchant_contacts.uid")





=begin
      # version 1
      numbers = MerchantContact.joins("LEFT JOIN messages ON merchant_contacts.uid = messages.to")
                .where("merchant_contacts.id in (#{uls.join(',')}) and merchant_contacts.is_customer = 0                         
                        and messages.id is null").pluck(:uid)

      # version 2
      numbers = MerchantContact.find_by_sql("select uid from merchant_contacts where merchant_id in (#{user_ids.join(',')}) 
                                          and is_customer = 0 
                      and uid not in 
                      ( 
                        select `to` as uid from messages where user_id in (#{user_ids.join(',')}) 
                        UNION ALL
                        select `from` as uid from messages where user_id_to in (#{user_ids.join(',')})
                      )")
=end
      
    
      csv_string = CSV.generate do |csv|
        csv << ['Phone Number']
        mcs.each { |mc| csv << [mc.uid] }
      end
      
      attachment_hash = { attachments: [ { content: Base64.encode64(csv_string),
                                            name: "file.csv",
                                            type: "text/csv" } ] }

      EmailingService.email_to_platform("See Attached for Numbers not texted", 'RMG Data', attachment_hash)
    end
    
  end
