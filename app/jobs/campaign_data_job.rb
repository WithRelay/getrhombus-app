# frozen_string_literal: true

class CampaignDataJob < ApplicationJob
  require 'csv'
  queue_as :campaign_data

  def perform(campaign_id)
    header = ['Phone Number', 'Call Display', 'Response', 'Segment', 'Campaign', 'Template', 'Timestamp (ET)',
              'Message ID', 'Segment ID', 'Campaign ID', 'VAN ID'].freeze
    campaign = Campaign.includes(user: :alert).find_by(id: campaign_id)
    # check customer_contact type
    first_customer_contact = campaign.user_lists.first

    if first_customer_contact.try(:customer_contact_type).present?
      query_string = "select
                        m.from as 'Phone Number', m.to as 'Call Display', m.text as 'Response',
                        l.name as 'Segment', c.name as 'Campaign',
                        c.text as 'Template', m.created_at as 'Timestamp (ET)',
                        m.id as 'Message ID', l.id as 'Segment ID', c.id as 'Campaign ID'
                        #{first_customer_contact.try(:customer_contact_type) == 'MerchantCustomer' ? '' : ", mc.van_id as 'VAN ID'"}
                      from campaigns c
                      inner join campaign_lists cl
                        on c.id = cl.campaign_id
                      inner join lists l
                        on l.id = cl.list_id
                      inner join user_lists ul
                        on ul.list_id = cl.list_id
                      inner join #{first_customer_contact.try(:customer_contact_type) == 'MerchantCustomer' ? 'merchant_customers' : 'merchant_contacts'} mc
                        on mc.id = ul.customer_contact_id
                      #{first_customer_contact.try(:customer_contact_type) == 'MerchantCustomer' ? 'inner join users u on mc.customer_id = u.id ' : ''}
                      inner join messages m
                        on m.from = #{first_customer_contact.try(:customer_contact_type) == 'MerchantCustomer' ? 'u.phone_number' : 'mc.uid'}
                      where c.id = ?
                        and m.user_id_to = ?
                        and m.created_at > ?"

      messages = Message.find_by_sql([query_string, campaign.id, campaign.user_id, campaign.created_at.to_s(:db)])

      csv_string = CSV.generate do |csv|
        csv << header
        messages.each do |m|
          csv << [m[header[0]], m[header[1]], m[header[2]], m[header[3]], m[header[4]], m[header[5]],
                  m[header[6]].to_time.strftime('%Y-%m-%d %H:%M:%S'), m[header[7]], m[header[8]], m[header[9]], m[header[10]]]
        end
      end

      emails = campaign.user.try(:alert).try(:emails)
      emails = emails.present? ? emails : [campaign.user.email]
      attachment_hash = { attachments: [{ content: Base64.encode64(csv_string), name: "#{campaign.name}.csv",
                                          type: 'text/csv' }] }
      emails.each do |e|
        EmailingService.email_to_platform(
          "See Attached File for account - #{campaign.user.email} and campaign - #{campaign.name}.", 'Campaign CSV Data', attachment_hash, e
        )
      end
    end
  rescue StandardError => e
    ExceptionNotifier.notify_exception(e, data: { message: 'In campaign data job', params: campaign_id })
  end
end
