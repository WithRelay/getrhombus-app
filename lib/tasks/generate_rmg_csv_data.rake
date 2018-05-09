
  desc "generate rmg csv data"
  task :generate_rmg_csv_data => :environment do
    require 'csv'
        
    csv_string = CSV.generate do |csv|
      csv << ['Phone Number', 'Response', 'Segment', 'Timestamp (ET)', 'ID']
      count = 0
      List.where(user_id: 2626, segment: nil).each do |l|
        UserList.where(list_id: l.id, customer_contact_type: 'MerchantContact').each do |ul|
          mc = MerchantContact.find_by(id: ul.customer_contact_id, is_customer: 0)
          if mc
            #messages = Message.where(from: mc.uid, user_id_to: 2626).where("created_at > '2018-04-18 16:58:25'") 
            messages = Message.where(from: mc.uid, user_id_to: 2626)#.where("id > 288990") 
            messages.each do |m| 
              csv << [m.from, m.text, l.name, m.created_at.strftime("%Y-%m-%d %H:%M:%S"), m.id] 
              count = count + 1
              puts count
            end
          end
        end
      end
    end

    attachment_hash = { attachments: [ { content: Base64.encode64(csv_string),
                                          name: "file.csv",
                                          type: "text/csv" } ] }

    EmailingService.email_to_platform("See Attached", 'RMG Data', attachment_hash)
    
  end
