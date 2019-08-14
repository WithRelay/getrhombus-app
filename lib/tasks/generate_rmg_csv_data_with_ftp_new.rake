desc 'generate rmg csv data with ftp'
task generate_rmg_csv_data_with_ftp_new: :environment do
  require 'csv'
  require 'tempfile'
  require 'net/sftp'

  CONTENT_SERVER_DOMAIN_NAME = '<redacted_ftp_domain>'.freeze
  CONTENT_SERVER_FTP_PASSWORD = '<redacted_password>'.freeze
  CONTENT_SERVER_FTP_LOGIN = '<redacted_ftp_username>'.freeze
  PORT = 22

  users = User.where("email like ? or email like ?", "<redacted_email>", "<redacted_email>").where(user_level: 1).where.not(id: [12569, 12570, 21401, 13119, 22480, 13118, 13117, 26863, 26633])


# c.text as 'Template', c.created_at as 'Campaign Sent (ET)', m.created_at as 'Timestamp (ET)',
# created_at should be updated_at
# and m.created_at is an issue... cos I can't use updated_at since that's after the campaign has ran and people could have responded since it ran... make a good guess
#     first_campaign = Campaign.where(user_id: user.id).where("created_at > ?", since_date_time).order(id: :asc).limit(1).first   ... this is the issue... should be updated_at

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
                  where c.updated_at > ?
                    and c.user_id = ?
                    and m.user_id_to = ?
                    and m.created_at > ?"


  messages = []
  filename = ''
  csv_string = ''
  temp_file = nil
  first_campaign = ''
  directory_created = false
  since_date_time = (Time.now.utc - 24.hours).to_s(:db).freeze
  date = (DateTime.now - 24.hours).strftime("%b %d, %Y").freeze
  remote_folder = "/DataGoesHere/test 1 Campaigns"
  header = ['Phone Number', 'Call Display', 'Response', 'Segment', 'Campaign', 'Template', 'Timestamp (ET)', 'Message ID', 'Segment ID', 'Campaign ID', 'VAN ID'].freeze

  users.each do |user|
    first_campaign = Campaign.where(user_id: user.id).where("updated_at > ?", since_date_time).order(updated_at: :asc).limit(1).first

    if first_campaign.try(:updated_at).present?
      #messages = Message.find_by_sql([query_string, since_date_time, user.id, user.id, first_campaign.created_at.to_s(:db)])
      messages = Message.find_by_sql([query_string, since_date_time, user.id, user.id, (first_campaign.updated_at - 2.hours).to_s(:db)])

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
