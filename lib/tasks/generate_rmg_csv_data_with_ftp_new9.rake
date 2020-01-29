desc 'generate rmg csv data with ftp'
task generate_rmg_csv_data_with_ftp_new9: :environment do
  require 'csv'
  require 'tempfile'
  require 'net/sftp'

  CONTENT_SERVER_DOMAIN_NAME = '<redacted_ftp_domain>'.freeze
  CONTENT_SERVER_FTP_PASSWORD = '<redacted_password>'.freeze
  CONTENT_SERVER_FTP_LOGIN = '<redacted_ftp_username>'.freeze
  PORT = 22

  users = User.where(email: [
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
  '<redacted_email>',
  '<redacted_email>',
  '<redacted_email>',
  '<redacted_email>',
  '<redacted_email>',
  '<redacted_email>',
  '<redacted_email>',
  '<redacted_email>'
  ].map(&:downcase)).pluck(:id, :email).to_h

  ids = users.keys

  filename = ''
  csv_string = ''
  temp_file = nil
  directory_created = false
  remote_folder = "/DataGoesHere/Jan 17, 2020 Request 1"
  header = ['Message ID', 'Phone Number', 'Timestamp ET', 'Message', 'Direction', 'Email'].freeze

  Message.select(:id, :from, :to, :created_at, :text, :user_id, :user_id_to)
  .where("user_id in (?) OR user_id_to in (?)", ids, ids).where("created_at > ?", "2019-11-13 04:00:00")
  .find_in_batches(batch_size: 999998).with_index do |messages, index|
    if messages.present?
      puts "batch #{index + 1}"
      recipient = nil
      direction = nil
      email = nil
      csv_string = CSV.generate do |csv|
        csv << header
        messages.each do |m|
          if users[m.user_id]
            recipient = m.to
            direction = 'out'
            email = users[m.user_id]
          else
            recipient = m.from
            direction = 'in'
            email = users[m.user_id_to]
          end
          csv << [m.id, recipient, m.created_at.to_time.strftime("%Y-%m-%d %H:%M:%S"), m.text, direction, email]
        end
      end

      # FTP Here
      puts 'Creating file'.freeze
      filename = "/home/taiwo/Desktop/Files/CPC.csv File #{index + 1}"
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
