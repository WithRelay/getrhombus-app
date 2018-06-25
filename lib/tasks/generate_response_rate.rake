


# 1. ADD INDEX TO `to` and `from` and `created_at`

desc "generate response rates"
task :generate_response_rates => :environment do
  require 'csv'

  count = 0
  campaign = Campaign.includes(user_lists: :customer_contact).find_by 282 # OPC: Message 2 (June 10)
  csv_string = CSV.generate do |csv|
    csv << ['Call Display', 'Phone Number', 'Outbound Text', 'Inbound Text', "Outbound Time", "Inbound Time", "Time Diff"]
  
    if campaign
      user_lists = campaign.user_lists.first

      if user_lists
        user_lists.each do |ul|
          conversation = Conversation.find_by(uid: ul.customer_contact.uid, merchant_id: campaign.user_id, uid_type: ul.customer_contact.uid_type)
          outbound = conversation.messages.where("`messages`.`user_id` = ? and `messages`.`to` = ? and `messages`.`created_at` > ?", campaign.user_id, ul.customer_contact.uid, campaign.created_at).order("`messages`.`id` ASC").limit(1)
          inbound = conversation.messages.where("`messages`.`user_id_to` = ? and `messages`.`from` = ? and `messages`.`created_at` > ?", campaign.user_id, ul.customer_contact.uid, campaign.created_at).order("`messages`.`id` ASC").limit(1)
          
          in_time = inbound.try(:created_at)
          out_time = outbound.try(:created_at)
          time_diff = out_time && in_time ? ((out_time.created_at - in_time.created_at) / 60) : ''

          csv << [outbound.try(:from), inbound.try(:from), outbound.try(:text), inbound.try(:text), out_time.try(:strftime, "%Y-%m-%d %H:%M:%S"), in_time.try(:strftime, "%Y-%m-%d %H:%M:%S"), time_diff] 

          count = count + 1
          puts count
        end
      end
    end

    attachment_hash = { attachments: [ { content: Base64.encode64(csv_string), name: "file.csv", type: "text/csv" } ] }
    EmailingService.email_to_platform("See Attached for Campaign - #{campaign.name}", 'RMG Data', attachment_hash)
  end
end


# 2. REMOVE INDEX from `to` and `from` and `created_at