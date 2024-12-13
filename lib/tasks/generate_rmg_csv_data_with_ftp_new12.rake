desc 'generate rmg csv data with ftp'
task generate_rmg_csv_data_with_ftp_new12: :environment do
  require 'csv'
  require 'tempfile'
  require 'net/sftp'

  PORT = 2202

  users = User.where(email: [
    '<redacted_email>',
    '<redacted_email>',
    '<redacted_email>'
  ].map(&:downcase))

  remote_folder = '/DataGoesHere/Jan 23, 2023 Request 1' # {date} Funnel Campaigns - All Accounts"
  header = %w[phone_number group email].freeze

  filename = ''
  temp_file = nil
  directory_created = false

  csv_string = CSV.generate do |csv|
    csv << header
    users.each do |user|
      user.lists.each do |list|
        puts list.inspect
        next if list.is_segment?

        mcs = list.x

        if list.customer?
          ActiveRecord::Associations::Preloader.new.preload(mcs, %i[customer])
          mcs.each do |mc|
            puts mc.customer.phone_number
            csv << [mc.customer.phone_number, list.name, user.email]
          end
        else
          mcs.each do |mc|
            puts mc.uid
            csv << [mc.uid, list.name, user.email]
          end
        end
      end
    end
  end

  # FTP Here
  puts 'Creating file'.freeze
  filename = 'phone numbers from segments.csv' # {user.email}.csv"
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
