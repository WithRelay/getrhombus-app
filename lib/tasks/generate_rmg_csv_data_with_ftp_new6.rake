desc 'generate rmg csv data with ftp'
task generate_rmg_csv_data_with_ftp_new6: :environment do
  require 'csv'
  require 'tempfile'
  require 'net/sftp'

  CONTENT_SERVER_DOMAIN_NAME = '<redacted_ftp_domain>'.freeze
  CONTENT_SERVER_FTP_PASSWORD = '<redacted_password>'.freeze
  CONTENT_SERVER_FTP_LOGIN = '<redacted_ftp_username>'.freeze
  PORT = 22

  #users = User.where("email like ? or email like ?", "<redacted_email>", "<redacted_email>").where(user_level: 1)#where.not(id: [12569, 12570, 21401, 13119, 22480, 13118, 13117, 26863, 26633])
  # users = User.where(id: [48162, 47945, 48188, 47943, 48175, 47942, 47944, 48186, 47941, 13912])
  #users = User.where(id: [49052])
  users = User.where(email: ['<redacted_email>'])

  query_string = "select
                    c.name as 'Campaign Name',
                    c.text as 'Template',
                    c.updated_at as 'Date Sent'
                  from campaigns c
                  inner join campaign_lists cl
                    on c.id = cl.campaign_id
                  inner join lists l
                    on l.id = cl.list_id
                  inner join user_lists ul
                    on ul.list_id = cl.list_id
                  inner join merchant_contacts mc
                    on mc.id = ul.customer_contact_id
                  inner join messages m
                    on m.from = mc.uid
                  where c.id = ?
                    and m.user_id_to = ?
                    and m.created_at > ?
                  group by m.from"
                    #and c.updated_at > ?"

                    #where c.updated_at > ?
                    #and c.updated_at < ?
                    #and c.user_id = ? yes
                    #and m.user_id_to = ? yes
                    #and m.created_at > ?" yes
                    #

  query_string2 = "select count(*) as 'Total'
            from campaign_lists cl
            inner join user_lists ul on cl.list_id = ul.list_id
            where cl.campaign_id = ?"

  query_string3 = "select count(*) as 'Total'
        from campaigns c
        inner join campaign_lists cl
          on c.id = cl.campaign_id
        inner join lists l
          on l.id = cl.list_id
        inner join user_lists ul
          on ul.list_id = cl.list_id
        inner join merchant_contacts mc
          on mc.id = ul.customer_contact_id
        inner join messages m
          on m.from = mc.uid
        where c.id = ?
          and m.user_id_to = ?
          and m.created_at > ?"
=begin
  query_string = "select
                    m.from as 'Phone Number', m.text as 'Response',
                    c.name as 'Campaign',
                    c.updated_at as 'Campaign Sent (ET)',
                    m.id as 'Message ID'
                  from campaigns c
                  inner join campaign_lists cl
                    on c.id = cl.campaign_id
                  inner join lists l
                    on l.id = cl.list_id
                  inner join user_lists ul
                    on ul.list_id = cl.list_id
                  inner join merchant_contacts mc
                    on mc.id = ul.customer_contact_id
                  inner join messages m
                    on m.from = mc.uid
                  where c.user_id = ?
                    and m.user_id_to = ?
                    and m.created_at > ?
                    and c.updated_at > ?
                    and c.updated_at < ?"
=end

  messages = []
  filename = ''
  csv_string = ''
  temp_file = nil
  first_campaign = ''
  directory_created = false
  #since_date_time = '2019-07-05 00:46:50'
  #since_date_time = (Time.now.utc - 40.hours).to_s(:db).freeze
  #max_date_time = '2019-07-06 01:57:49' #(Time.now.utc - 24.hours).to_s(:db).freeze
  #date = (DateTime.now - 24.hours).strftime("%b %d, %Y").freeze #(DateTime.now).strftime("%b %d, %Y").freeze
  remote_folder = "/DataGoesHere/Nov 18, 2019 Request 1" #{date} Funnel Campaigns - All Accounts"
  header = ['Total', 'Campaign Name', 'Date Sent', 'Email', 'Template', 'Unique Inbound Numbers', 'Total Inbound messages'].freeze

  csv_string = CSV.generate do |csv|
    csv << header
    users.each_with_index do |user,i|
      puts "#{user.email} - #{i} of #{users.size}"
      messages = []
      campaigns = Campaign.where(user_id: user.id).where("updated_at > '2019-11-01 03:59:59'").order(id: :asc)

      if campaigns.present?
        campaigns.each_with_index do |c, i|
          puts "campaign  #{c.name}"
          messages.concat(Message.find_by_sql([query_string, c.id, user.id, '2019-11-01 03:59:59']))
          total = CampaignList.find_by_sql([query_string2, c.id]).first['Total']
          total_messages = Message.find_by_sql([query_string3, c.id, user.id, '2019-11-01 03:59:59']).first['Total']
          csv << [total, c.name, c.updated_at.to_time.strftime("%Y-%m-%d"), user.email, c.text, messages.length, total_messages]
          messages = []
        end
      end
    end
  end

  # FTP Here
  puts 'Creating file'.freeze
  filename = "Campaign data Since Nov 1st.csv" #{user.email}.csv"
  temp_file = Tempfile.new(filename)
  temp_file.write(csv_string)
  temp_file.close

  puts 'connecting to ftp'.freeze
  Net::SFTP.start(CONTENT_SERVER_DOMAIN_NAME, CONTENT_SERVER_FTP_LOGIN, { password: CONTENT_SERVER_FTP_PASSWORD, port: PORT }) do |sftp|
    begin
      sftp.mkdir!(remote_folder) unless directory_created
      directory_created = true
    rescue Net::SFTP::StatusException => e
    end
    # upload a file or directory to the remote host
    sftp.upload!(temp_file.path, "#{remote_folder}/#{filename}")
  end
  temp_file.close!
  puts 'exiting ftp'.freeze
end
