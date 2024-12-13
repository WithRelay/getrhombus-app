desc 'generate rmg csv data with ftp'
task generate_rmg_csv_data_with_ftp_new8: :environment do
  require 'csv'
  require 'tempfile'
  require 'net/sftp'

  PORT = 22

  users = User.where(email: ['<redacted_email>'])

  query_string = "select
                    count(*) as 'Total'
                  from messages
                  where user_id = ? and created_at > ?"

  query_string2 = "select
                    count(*) as 'Total'
                  from messages
                  where user_id_to = ? and created_at > ?"

  messages = []
  filename = ''
  csv_string = ''
  temp_file = nil
  first_campaign = ''
  directory_created = false
  # since_date_time = '2019-07-05 00:46:50'
  # since_date_time = (Time.now.utc - 40.hours).to_s(:db).freeze
  # max_date_time = '2019-07-06 01:57:49' #(Time.now.utc - 24.hours).to_s(:db).freeze
  # date = (DateTime.now - 24.hours).strftime("%b %d, %Y").freeze #(DateTime.now).strftime("%b %d, %Y").freeze
  remote_folder = '/DataGoesHere/Oct 23, 2019 Request 2' # {date} Funnel Campaigns - All Accounts"
  header = ['Account', 'Outbound Messages (since Sep11)', 'Inbound Messages (Since Sep11)'].freeze

  csv_string = CSV.generate do |csv|
    csv << header
    users.each_with_index do |user, i|
      puts "#{user.email} - #{i} of #{users.size}"
      total_outbound = Message.find_by_sql([query_string, user.id, '2019-09-11 03:59:59']).first['Total']
      total_inbound = Message.find_by_sql([query_string2, user.id, '2019-09-11 03:59:59']).first['Total']
      csv << [user.email, total_outbound, total_inbound]
    end
  end

  # FTP Here
  puts 'Creating file'.freeze
  filename = 'Strong Data.csv' # {user.email}.csv"
  temp_file = Tempfile.new(filename)
  temp_file.write(csv_string)
  temp_file.close

  puts 'connecting to ftp'.freeze
  Net::SFTP.start(CONTENT_SERVER_DOMAIN_NAME, CONTENT_SERVER_FTP_LOGIN,
                  { password: CONTENT_SERVER_FTP_PASSWORD, port: PORT }) do |sftp|
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
