desc 'generate rmg csv data with ftp'
task generate_rmg_csv_data_with_ftp4: :environment do
  require 'csv'
  require 'tempfile'
  require 'net/sftp'

  CONTENT_SERVER_DOMAIN_NAME = '<redacted_ftp_domain>'.freeze
  CONTENT_SERVER_FTP_LOGIN = '<redacted_ftp_username>'.freeze
  CONTENT_SERVER_FTP_PASSWORD = '<redacted_password>'.freeze
  PORT = 22

  # campaign = Campaign.includes(user: :alert, user_lists: :customer_contact).find_by(id: campaign_id)
  # .where("id in (?) and user_id = ?", [5912, 5913, 5876, 5878, 5879, 5880, 5881, 5882, 5883, 5884, 5885, 5886], user_id)

  # .where(id: [10507]) #10731

  date = DateTime.now.strftime("%b %d, %Y")
  directory_created = false

  # WOULD BE GOOD TO KNOW THE TOTAL OR WHEN THIS IS DONE
  Campaign.includes(:user, user_lists: [:customer_contact])
          .where(user_id: [13912])
          .where("created_at > '2019-06-01 00:00:00'")
          .find_in_batches(batch_size: 20)
          .with_index do |campaigns, index|

    csv_string = CSV.generate do |csv|
      count = 0
      csv << ['Phone Number', 'Call Display', 'Response', 'Segment', 'Campaign', 'Template', 'Timestamp (ET)', 'Message ID', 'Segment ID', 'Campaign ID', 'Account', 'Campaign Sent (ET)']

      campaigns.each do |campaign|
        next if campaign.try(:user_lists).blank?

        user = campaign.user
        user_id = campaign.user_id
        list = campaign.user_lists.first.try(:list)

        campaign.user_lists.each do |ul|
          next if ul.customer_contact.blank?

          if ul.customer_contact_type == 'MerchantCustomer'
            messages = Message.where("user_id_to = #{user_id} and user_id = #{ul.customer_contact.customer_id} and created_at > '#{campaign.created_at.to_s(:db)}'")
          else
            messages = Message.where("user_id_to = #{user_id} and `from` = #{ul.customer_contact.uid} and created_at > '#{campaign.created_at.to_s(:db)}'")
          end

          messages.each do |m|
            csv << [m.from, m.to, m.text, list.try(:name), campaign.name, campaign.text, m.created_at.strftime('%Y-%m-%d %H:%M:%S'), m.id, list.try(:id), campaign.id, user.email, campaign.created_at.strftime('%Y-%m-%d %H:%M:%S')]
            count += 1
            puts count
          end
        end

        # FTP Here
        puts 'Creating file'
        filename = "#{user.email} - #{campaign.name}.csv"
        temp_file = Tempfile.new(filename)
        temp_file.write(csv_string)
        temp_file.close

        puts 'connecting to ftp'
        Net::SFTP.start(CONTENT_SERVER_DOMAIN_NAME, CONTENT_SERVER_FTP_LOGIN, { password: CONTENT_SERVER_FTP_PASSWORD, port: PORT }) do |sftp|
          begin
            sftp.mkdir!("/DataGoesHere/#{date}") unless directory_created
            directory_created = true
          rescue Net::SFTP::StatusException => e
          end
          # upload a file or directory to the remote host
          sftp.upload!(temp_file.path, "/DataGoesHere/#{date}/#{filename}")
        end
        temp_file.close!
        puts 'exiting ftp'
      end
    end
  end
end
