desc 'generate rmg csv data with ftp'
task generate_rmg_data_outbound: :environment do
  require 'csv'
  require 'tempfile'
  require 'net/sftp'

  CONTENT_SERVER_DOMAIN_NAME = '<redacted_ftp_domain>'.freeze
  CONTENT_SERVER_FTP_PASSWORD = '<redacted_password>'.freeze
  CONTENT_SERVER_FTP_LOGIN = '<redacted_ftp_username>'.freeze
  PORT = 22

  users = User.where(email: ["<redacted_email>",
    "<redacted_email>",
    "<redacted_email>",
    "<redacted_email>",
    "<redacted_email>",
    "<redacted_email>",
    "<redacted_email>",
    "<redacted_email>",
    "<redacted_email>",
    "<redacted_email>",
    "<redacted_email>",
    "<redacted_email>",
    "<redacted_email>",
    "<redacted_email>",
    "<redacted_email>",
    "<redacted_email>",
    "<redacted_email>",
    "<redacted_email>",
    "<redacted_email>",
    "<redacted_email>",
    "<redacted_email>",
    "<redacted_email>",
    "<redacted_email>",
    "<redacted_email>",
    "<redacted_email>",
    "<redacted_email>",
    "<redacted_email>",
    "<redacted_email>",
    "<redacted_email>"
  ])

  filename = ''
  csv_string = ''
  temp_file = nil
  directory_created = false
  remote_folder = "/DataGoesHere/Oct 09, 2019 Request 2" #{date} Funnel Campaigns - All Accounts"
  header = ['Phone Number', 'Datestamp'].freeze

  users.each_with_index do |user,i|
    puts "#{user.email} - #{i} of #{users.size}"
    Message.select(:id, :created_at, :to).where(user_id: user.id).where("`created_at` > '2019-09-03 04:00:00'").find_in_batches(batch_size: 999998).with_index do |messages, index|
      if messages.present?
        csv_string = CSV.generate do |csv|
          csv << header
          messages.each { |m| csv << [m.to, m.created_at.to_time.strftime("%Y-%m-%d %H:%M:%S")] }
        end

        # FTP Here
        puts 'Creating file'.freeze
        filename = "#{user.email}.csv File #{index + 1}"
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
end
