


# 1. ADD INDEX TO `to` and `from` and `created_at`

desc "generate response rates"
task :generate_response_rates => :environment do
  require 'csv'

  #[316, 317, 322, 323, 327, 328, 329, 330, 331, 332, 335, 336].each do |cid|
  [580,310,329,335,312,402,547,576,315,316,327,331,337,343,347,356,678,406,573,577,317,328,332,338,344,348,357,679,421,574,578,
    311,322,341,345,353,399,401,536,575,579,323,330,336,342,346,355].sort.each do |cid|

    count = 0
    campaign = Campaign.includes(user_lists: :customer_contact).find_by(id: cid)
    
    csv_string = CSV.generate do |csv|
      csv << ['Call Display', 'Phone Number', 'Outbound Text', 'Inbound Text', "Outbound Time (ET)", "Inbound Time (ET)", "Time Diff (Minutes)"]
    
      if campaign.try(:user_lists).present?
        campaign.user_lists.each do |ul|
          outbound = Message.where("user_id = ? and `messages`.`to` = ? and created_at > ?", campaign.user_id, ul.customer_contact.uid, campaign.created_at).order(id: :asc).first
          inbound = Message.where("user_id_to = ? and `messages`.`from` = ? and created_at > ?", campaign.user_id, ul.customer_contact.uid, campaign.created_at).order(id: :asc).first

          out_time = outbound.try(:created_at)
          in_time = inbound.try(:created_at)
          time_diff = out_time && in_time ? ((in_time - out_time) / 60) : ''

          csv << [outbound.try(:from), inbound.try(:from), outbound.try(:text), inbound.try(:text), out_time.try(:strftime, "%Y-%m-%d %H:%M:%S"), in_time.try(:strftime, "%Y-%m-%d %H:%M:%S"), time_diff]

          count = count + 1
          puts count
        end
      end
    end

    attachment_hash = { attachments: [ { content: Base64.encode64(csv_string), name: "#{campaign.name}.csv", type: "text/csv" } ] }
    EmailingService.email_to_platform("See Attached for Campaign - #{campaign.name}", 'RMG Data', attachment_hash, "<redacted_email>")
  end
end


# 2. REMOVE INDEX from `to` and `from` and `created_at
# 3. REMOVE Migration file And DB Schema_migrations