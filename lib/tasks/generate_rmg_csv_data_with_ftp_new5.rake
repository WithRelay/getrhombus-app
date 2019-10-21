desc 'generate rmg csv data with ftp'
task generate_rmg_csv_data_with_ftp_new5: :environment do
  require 'csv'
  require 'tempfile'
  require 'net/sftp'

  CONTENT_SERVER_DOMAIN_NAME = '<redacted_ftp_domain>'.freeze
  CONTENT_SERVER_FTP_PASSWORD = '<redacted_password>'.freeze
  CONTENT_SERVER_FTP_LOGIN = '<redacted_ftp_username>'.freeze
  PORT = 22

  users = User.where(email: ['<redacted_email>',
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
    '<redacted_email>', #### needs to be redone
    '<redacted_email>',  #### needs to be redone
    '<redacted_email>',
    '<redacted_email>',
    '<redacted_email>',
    '<redacted_email>',
    '<redacted_email>',
    '<redacted_email>',
    '<redacted_email>',
    '<redacted_email>'
  ])

  #users = User.where(email: ['<redacted_email>'])

  filename = ''
  csv_string = ''
  temp_file = nil
  directory_created = false
  remote_folder = "/DataGoesHere/Oct 18, 2019 Request 2"
  header = ['Message ID', 'Phone Number', 'Timestamp ET', 'Message', 'Direction'].freeze

  users.each_with_index do |user,i|
    puts "#{user.email} - #{i} of #{users.size}"
    Message.select(:id, :from, :to, :created_at, :text, :user_id, :user_id_to).where("created_at > '2019-10-11 03:59:59'").where("user_id = ? OR user_id_to = ?", user.id, user.id).find_in_batches(batch_size: 999998).with_index do |messages, index|
      if messages.present?
        puts "batch #{index + 1}"
        recipient = nil
        direction = nil
        csv_string = CSV.generate do |csv|
          csv << header
          messages.each do |m|
            if m.user_id == user.id
              recipient = m.to
              direction = 'out'
            else
              recipient = m.from
              direction = 'in'
            end
            csv << [m.id, recipient, m.created_at.to_time.strftime("%Y-%m-%d %H:%M:%S"), m.text, direction]
          end
        end

        # FTP Here
        puts 'Creating file'.freeze
        filename = "/home/taiwo/Desktop/Files/#{user.email}.csv File #{index + 1}"
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
end
