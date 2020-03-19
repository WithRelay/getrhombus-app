desc 'generate rmg csv data with ftp'
task generate_rmg_csv_data_with_ftp_new10: :environment do
  require 'csv'
  require 'tempfile'
  require 'net/sftp'

  CONTENT_SERVER_DOMAIN_NAME = '<redacted_ftp_domain>'.freeze
  CONTENT_SERVER_FTP_PASSWORD = '<redacted_password>'.freeze
  CONTENT_SERVER_FTP_LOGIN = '<redacted_ftp_username>'.freeze
  PORT = 22

  users = User.where("email like ? or email like ?", "<redacted_email>", "<redacted_email>")
              .where(user_level: 1).where.not(id: [12569, 12570, 21401, 13119, 22480, 13118, 13117, 26863, 26633])
              .pluck(:id, :email).to_h

  #users = User.where(id: 61982).pluck(:id, :email).to_h

  ids = users.keys

  filename = ''
  csv_string = ''
  temp_file = nil
  directory_created = false
  since_date_time = Time.current.yesterday.beginning_of_day #.to_s(:db).freeze
  till_date_time = Time.current.beginning_of_day
  date = DateTime.now.yesterday.strftime("%b %d, %Y").freeze
  remote_folder = "/DataGoesHere/#{date} IO Data"
  header = ['Message ID', 'Phone Number', 'Timestamp ET', 'Message', 'Direction', 'Email'].freeze

  Message.select(:id, :from, :to, :created_at, :text, :user_id, :user_id_to)
  .where("user_id in (?) OR user_id_to in (?)", ids, ids).where("created_at >= ? and created_at < ?", since_date_time, till_date_time)
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
          csv << [m.id, recipient, m.created_at.strftime("%Y-%m-%d %H:%M:%S"), m.text, direction, email]
        end
      end

      # FTP Here
      puts 'Creating file'.freeze
      filename = "File #{index + 1}.csv"
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
