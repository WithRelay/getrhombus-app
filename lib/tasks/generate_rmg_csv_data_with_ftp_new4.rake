desc 'generate rmg csv data with ftp'
task generate_rmg_csv_data_with_ftp_new4: :environment do
  require 'csv'
  require 'tempfile'
  require 'net/sftp'

  CONTENT_SERVER_DOMAIN_NAME = '<redacted_ftp_domain>'.freeze
  CONTENT_SERVER_FTP_PASSWORD = '<redacted_password>'.freeze
  CONTENT_SERVER_FTP_LOGIN = '<redacted_ftp_username>'.freeze
  PORT = 22

  #users = User.where("email like ? or email like ?", "<redacted_email>", "<redacted_email>").where(user_level: 1).where.not(id: [12569, 12570, 21401, 13119, 22480, 13118, 13117, 26863, 26633])
  # users = User.where(id: [48162, 47945, 48188, 47943, 48175, 47942, 47944, 48186, 47941, 13912])
  #users = User.where(id: [49052])
  users = User.where(email: ["<redacted_email>", "<redacted_email>", "<redacted_email>", "<redacted_email>", "<redacted_email>", "<redacted_email>", "<redacted_email>", "<redacted_email>", "<redacted_email>", "<redacted_email>", "<redacted_email>", "<redacted_email>", "<redacted_email>", "<redacted_email>", "<redacted_email>", "<redacted_email>", "<redacted_email>", "<redacted_email>", "<redacted_email>", "<redacted_email>", "<redacted_email>", "<redacted_email>", "<redacted_email>"])

  query_string = "select
                    m.from as 'Phone Number', m.to as 'Call Display', m.text as 'Response',
                    l.name as 'Segment', c.name as 'Campaign',
                    c.text as 'Template', c.updated_at as 'Campaign Sent (ET)', m.created_at as 'Timestamp (ET)',
                    m.id as 'Message ID', c.id as 'Campaign ID', l.id as 'Segment ID'
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
                    #and c.updated_at > ?"

                    #where c.updated_at > ?
                    #and c.updated_at < ?
                    #and c.user_id = ? yes
                    #and m.user_id_to = ? yes
                    #and m.created_at > ?" yes
                    #


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
  remote_folder = "/DataGoesHere/Aug 28, 2019 Request 1" #{date} Funnel Campaigns - All Accounts"
  header = ['Phone Number', 'Call Display', 'Response', 'Segment', 'Campaign', 'Template', 'Timestamp (ET)', 'Message ID', 'Segment ID', 'Campaign ID', 'VAN ID'].freeze

  users.each_with_index do |user,i|
    puts "#{user.email} - #{i} of #{users.size}"
    messages = []
    campaigns = Campaign.where(user_id: user.id).order(id: :asc)

    campaigns.each do |c|
      puts "campaign  #{c.name}"
      messages.concat(Message.find_by_sql([query_string, c.id, user.id, c.created_at.to_s(:db)]))
    end

    if messages.present?
      csv_string = CSV.generate do |csv|
        csv << header
        messages.each { |m| csv << [m[header[0]], m[header[1]], m[header[2]], m[header[3]], m[header[4]], m[header[5]], m[header[6]].to_time.strftime("%Y-%m-%d %H:%M:%S"), m[header[7]], m[header[8]], m[header[9]]] }
      end

      # FTP Here
      puts 'Creating file'.freeze
      filename = "#{user.email}.csv"
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
  end
end
