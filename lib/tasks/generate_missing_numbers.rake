
  desc "generate_missing_numbers"
  task :generate_missing_numbers => :environment do
    require 'csv'    

    user_ids = [7732, 7889, 7890, 7891, 7892, 7893]
    lists = List.where(user_id: user_ids, segment: nil).pluck(:id)
    puts lists.inspect
    uls = UserList.where(list_id: lists, customer_contact_type: 'MerchantContact').pluck(:customer_contact_id)
    puts uls.inspect

    if uls.present?
      messages = Message.joins("LEFT JOIN merchant_contacts mc ON mc.uid = messages.to")
                  .where("mc.id in (#{uls.join(',')}) and mc.is_customer = 0 and messages.user_id in (#{user_ids.join(',')}) and messages.to is null")
                  .pluck(:from)
    
      csv_string = CSV.generate do |csv|
        csv << ['Phone Number']
        messages.each { |number| csv << [number] }
      end
      
      attachment_hash = { attachments: [ { content: Base64.encode64(csv_string),
                                            name: "file.csv",
                                            type: "text/csv" } ] }

      EmailingService.email_to_platform("See Attached for Numbers not texted", 'RMG Data', attachment_hash)
    end
    
  end
