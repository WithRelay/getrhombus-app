module ListsHelper

  def list_show_partial
    @list.contact? ? 'list_contact' : 'list_customer'
  end

  def list_last_sent(list)
    last_sent = list.last_campaign_recipient # campaign_recipients.last
    last_sent.present? ? time_in_relative_form(last_sent.created_at, 'long_format') : "-"
  end
end
