
  desc "generate_missing_numbers"
  task :generate_missing_numbers => :environment do
    require 'csv'
        

=begin
    [7732, 7889, 7890, 7891, 7892, 7893].each do |user_id|    
      
      csv_string = CSV.generate do |csv|
        csv << ['Phone Number']
        lists = List.where(user_id: user_id, segment: nil).pluck(:id)
        uls = UserList.where(list_id: lists, customer_contact_type: 'MerchantContact').pluck(:customer_contact_id)            
        numbers = MerchantContact.find_by(id: uls, is_customer: 0).pluck(:uid)
            if mc
              #messages = Message.where(from: mc.uid, user_id_to: user_id).where("created_at > '2018-04-18 16:58:25'") 
              messages = Message.where(from: mc.uid, user_id_to: user_id)#.where("id > 288990") 
              messages.each do |m| 
                csv << [m.from, m.text, l.name, m.created_at.strftime("%Y-%m-%d %H:%M:%S"), m.id] 
                #count = count + 1
                #puts count
              end
            end
          end
        end
      end

      attachment_hash = { attachments: [ { content: Base64.encode64(csv_string),
                                            name: "file.csv",
                                            type: "text/csv" } ] }

      EmailingService.email_to_platform("See Attached for User ID #{user_id}", 'RMG Data', attachment_hash)
    end
=end
    
  end
