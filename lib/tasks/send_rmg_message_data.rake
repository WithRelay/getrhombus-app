



desc "send rmg message data"
task :send_rmg_message_data => :environment do
  user_id = 7732

  require 'csv'
        
    csv_string = CSV.generate do |csv|
      csv << ['Call Display', 'Phone Number', 'Response', 'Timestamp (ET)']
      count = 0

      messages = Message.where(user_id_to: user_id)#.where("id > 288990") 
      messages.each do |m| 
        csv << [m.to, m.from, m.text, m.created_at.strftime("%Y-%m-%d %H:%M:%S")] 
        count = count + 1
        puts count
      end

    end

    attachment_hash = { attachments: [ { content: Base64.encode64(csv_string),
                                          name: "file.csv",
                                          type: "text/csv" } ] }

    EmailingService.email_to_platform("See Attached", 'RMG Data', attachment_hash)
    
end


