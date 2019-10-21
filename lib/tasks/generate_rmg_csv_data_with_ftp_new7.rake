desc 'generate rmg csv data with ftp'
task generate_rmg_csv_data_with_ftp_new7: :environment do
=begin
  require 'csv'
  require 'tempfile'
  require 'net/sftp'

  CONTENT_SERVER_DOMAIN_NAME = '<redacted_ftp_domain>'.freeze
  CONTENT_SERVER_FTP_PASSWORD = '<redacted_password>'.freeze
  CONTENT_SERVER_FTP_LOGIN = '<redacted_ftp_username>'.freeze
  PORT = 22

  emails = [['<redacted_email>',
'<redacted_email>',
'<redacted_email>',
'<redacted_email>',
'<redacted_email>',
'<redacted_email>',
'<redacted_email>',
'<redacted_email>',
'<redacted_email>',
'<redacted_email>',
'<redacted_email>',
'<redacted_email>',
'<redacted_email>',
'<redacted_email>',
'<redacted_email>',
'<redacted_email>',
'<redacted_email>',
'<redacted_email>',
'<redacted_email>',
'<redacted_email>',
'<redacted_email>',
'<redacted_email>',
'<redacted_email>',
'<redacted_email>',
'<redacted_email>',
'<redacted_email>',
'<redacted_email>',
'<redacted_email>',
'<redacted_email>',
'<redacted_email>',
'<redacted_email>',
'<redacted_email>',
'<redacted_email>',
'<redacted_email>',
'<redacted_email>',
'<redacted_email>',
'<redacted_email>',
'<redacted_email>',
'<redacted_email>',
'<redacted_email>',
'<redacted_email>',
'<redacted_email>',
'<redacted_email>',
'<redacted_email>',
'<redacted_email>',
'<redacted_email>',
'<redacted_email>',
'<redacted_email>',
'<redacted_email>',
'<redacted_email>',
'<redacted_email>',
'<redacted_email>',
'<redacted_email>',
'<redacted_email>',
'<redacted_email>',
'<redacted_email>',
'<redacted_email>',
'<redacted_email>',
], ['<redacted_email>',
'<redacted_email>',
'<redacted_email>',
'<redacted_email>',
'<redacted_email>',
'<redacted_email>',
'<redacted_email>',
'<redacted_email>',
'<redacted_email>',
'<redacted_email>',
'<redacted_email>',
'<redacted_email>',
'<redacted_email>',
'<redacted_email>',
'<redacted_email>',
'<redacted_email>',
'<redacted_email>',
'<redacted_email>',
'<redacted_email>',
'<redacted_email>',
'<redacted_email>',
'<redacted_email>',
'<redacted_email>',
'<redacted_email>',
'<redacted_email>',
'<redacted_email>',
'<redacted_email>',
'<redacted_email>',
'<redacted_email>',
'<redacted_email>',
'<redacted_email>',
'<redacted_email>',
'<redacted_email>',
'<redacted_email>',
'<redacted_email>',
'<redacted_email>',
'<redacted_email>',
]]

  filename = ''
  csv_string = ''
  temp_file = nil
  directory_created = false
  remote_folder = "/DataGoesHere/Oct 18, 2019 Request 2"
  header = ['Phone Number', 'Message'].freeze

  emails.each do |email_ary|
    ids = User.where(email: email_ary).pluck(:id)
    puts ids.inspect
    Message.select(:id, :from, :text).where(user_id_to: ids).find_in_batches(batch_size: 999998).with_index do |messages, index|
      if messages.present?
        puts "batch #{index + 1}"
        csv_string = CSV.generate do |csv|
          csv << header
          messages.each do |m|
            csv << [m.from, m.text]
          end
        end

        # FTP Here
        puts 'Creating file'.freeze
        filename = "/home/taiwo/Desktop/Files/#{email_ary[0]}.csv File #{index + 1}"
        #temp_file = Tempfile.new(filename)
        #temp_file.write(csv_string)
        #temp_file.close
        File.write(filename, csv_string)
        puts 'File created'.freeze

        #puts 'connecting to ftp'.freeze
        #Net::SFTP.start(CONTENT_SERVER_DOMAIN_NAME, CONTENT_SERVER_FTP_LOGIN, { password: CONTENT_SERVER_FTP_PASSWORD, port: PORT }) do |sftp|
        #  begin
        #    sftp.mkdir!(remote_folder) unless directory_created
        #    directory_created = true
        #  rescue Net::SFTP::StatusException => e
        #  end
        #  # upload a file or directory to the remote host
        #  sftp.upload!(temp_file.path, "#{remote_folder}/#{filename}")
        #end
        #temp_file.close!
        #puts 'exiting ftp'.freeze
      end
    end
  end
=end


end
