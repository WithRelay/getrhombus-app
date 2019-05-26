class CampaignDataJob < ApplicationJob
  require 'csv'
  queue_as :campaign_data

  def perform(campaign_id)
    campaign = Campaign.includes(user: :alert, user_lists: :customer_contact).find_by(id: campaign_id)

    csv_string = CSV.generate do |csv|
      count = 0
      csv << ['Phone Number', 'Call Display', 'Response', 'Segment', 'Campaign', 'Template', 'Timestamp (ET)', 'Message ID', 'Segment ID', 'Campaign ID', 'VAN ID']
      if campaign.try(:user_lists).present?
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
            csv << [m.from, m.to, m.text, list.try(:name), campaign.name, campaign.text, m.created_at.strftime('%Y-%m-%d %H:%M:%S'), m.id, list.try(:id), campaign.id, ul.customer_contact.try(:van_id)]
            count += 1
          end
        end
      end
    end

    emails = campaign.user.try(:alert).try(:emails)
    emails = emails.present? ? emails : [campaign.user.email]
    attachment_hash = { attachments: [{ content: Base64.encode64(csv_string), name: 'file.csv', type: 'text/csv' }] }
    emails.each do |e|
      EmailingService.email_to_platform("See Attached File for account - #{campaign.user.email} and campaign - #{campaign.name}.", 'Campaign CSV Data', attachment_hash, e)
    end
  rescue StandardError => e
    ExceptionNotifier.notify_exception(e, data: { message: 'In campaign data job', params: campaign_id })
  end
end
