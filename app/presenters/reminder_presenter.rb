class ReminderPresenter < BasePresenter
  def reminder_change_status_link
    return 'Inactive' if @model.inactive?
    text = @model.paused? ? 'Unpause' : 'Pause'
    h.link_to(
      text,
      change_status_user_reminder_path(@user, @model),
      method: :put,
      class: 'reminder actions-button cancel'
    )
  end

  def get_channel
    channel_hash = { facebook_messenger: 'Messenger', sms: 'SMS' }
    channel_hash[@model.channel]
  end

  def customer_contact
    @model.user_lists.first.customer_contact
  end

  def format_last_visit
    mc = customer_contact
    mc && mc.updated_at ? mc.updated_at.strftime('%d/%m/%y') : '-'
  end

  def get_display_name_and_number_and_recipient_hash
    mc = customer_contact
    if mc.class == MerchantCustomer
      user = mc.customer
      uid, uid_type, number, description = user.id, 'user', user.phone_number, user.phone_number
      title = user.card_name.present? ? user.card_name : user.email
    else
      user, uid, uid_type, number = nil, mc.uid, mc.uid_type, (mc.uid_type == 'phone_number' ? uid : 'Messenger')
      title = mc.uid_type == 'phone_number' ? uid : "#{FbCred.where(page_specific_id: mc.uid).try(:first).try(:name)}"
      description = mc.uid_type == 'phone_number' ? 'SMS Contact' : 'Messenger Contact'
    end

    {
      name: User.get_conversation_display_name(uid, uid_type, user),
      number: number,
      recipient: {
        uid_type: uid_type,
        uid: uid,
        unique_identifier: "#{mc.id}-#{mc.class}",
        title: title,
        description: description
      }
    }
  end

  def recipient_profile_link
    mc = customer_contact
    "#{mc.class == MerchantCustomer ? 'customers' : 'contacts'}/#{mc.id}"
  end
end
