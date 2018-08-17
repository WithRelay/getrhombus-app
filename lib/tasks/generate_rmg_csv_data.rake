
  desc "generate rmg csv data"
  task :generate_rmg_csv_data => :environment do
    require 'csv'
  
=begin      
    [2626].each do |user_id|    
      
      csv_string = CSV.generate do |csv|
        csv << ['Phone Number', 'Response', 'Segment', 'Campaign', 'Timestamp (ET)', 'Message ID', 'Segment ID', 'Campaign ID']
        #count = 0
        List.where(user_id: user_id, segment: nil).each do |l|
          cl = CampaignList.where(list_id: l.id).last
          c = Campaign.find_by(id: cl.campaign_id) if cl
          UserList.where(list_id: l.id, customer_contact_type: 'MerchantContact').each do |ul|
            mc = MerchantContact.find_by(id: ul.customer_contact_id, is_customer: 0)
            if mc
              messages = Message.where(user_id_to: user_id, from: mc.uid).where("created_at > '2018-06-08 00:00:00'") 
              #messages = Message.where(user_id_to: user_id, from: mc.uid)#.where("id > 288990") 
              messages.each do |m| 
                csv << [m.from, m.text, l.name, c.try(:name), m.created_at.strftime("%Y-%m-%d %H:%M:%S"), m.id, l.id, c.try(:id)] 
                #count = count + 1
                #puts count
              end
            end
          end
        end
      end

      attachment_hash = { attachments: [ { content: Base64.encode64(csv_string), name: "file.csv", type: "text/csv" } ] }
      EmailingService.email_to_platform("See Attached for User ID #{user_id}", 'RMG Data', attachment_hash)
    end
=end

    [14821].each do |user_id|    
      
      csv_string = CSV.generate do |csv|
        count = 0
        csv << ['Phone Number', 'Response', 'Segment', 'Campaign', 'Timestamp (ET)', 'Message ID', 'Segment ID', 'Campaign ID']
        campaigns = Campaign.includes(user_lists: :customer_contact).where("id in (?) and user_id = ?", [2410, 2411, 2412], user_id)

        campaigns.each do |campaign|
          if campaign.try(:user_lists).present?
            list = campaign.user_lists.first.try(:list)
            campaign.user_lists.each do |ul|
              if ul.customer_contact.present?
                messages = Message.where("user_id_to = #{user_id} and `from` = #{ul.customer_contact.uid} and created_at > '#{campaign.created_at.to_s(:db)}'") 
                messages.each do |m| 
                  csv << [m.from, m.text, list.try(:name), campaign.name, m.created_at.strftime("%Y-%m-%d %H:%M:%S"), m.id, list.try(:id), campaign.id] 
                  count = count + 1
                  puts count
                end
              end
            end
          end
        end
      end

      attachment_hash = { attachments: [ { content: Base64.encode64(csv_string), name: "file.csv", type: "text/csv" } ] }
      EmailingService.email_to_platform("See Attached for User ID #{user_id}", 'RMG Data', attachment_hash)
    end
    
  end
