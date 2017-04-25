class RealtimeStreamService

  class << self

    # might need to redo how conv_ref is sent
    # Sends a message to the given merchant's channel, provided user and merchant numbers
    def messages(conversation, conv_ref, merchant, customer, msg)
      merchant_id = conversation.merchant_id.to_s
      $pubnub.subscribe(channel: 'messaging_' + Rails.env + '_' + merchant_id) {}
      $pubnub.publish(channel: 'messaging_' + Rails.env + '_' + merchant_id,
                      message: { type: 'new-message',
                                 message: Conversation.message_hash(conversation, msg, conv_ref, customer),
                                 conversation: conversation.conversation_hash }.to_json) {}
    end

    def update_conversation_properties(conversation_id, customer, merchant_id, old_selectize_val)
      $pubnub.publish(channel: 'messaging_' + Rails.env + '_' + merchant_id.to_s,
                      message: { type: 'update-conv-properties', id: conversation_id,
                                 full_name: User.get_conversation_display_name(customer.id, "user"),
                                 profile_image: User.check_profile_picture(customer),
                                 old_selectize_val: old_selectize_val,
                                 selectize: { uid: customer.id, uid_type: 'user',
                                              description: customer.phone_number,
                                              unique_identifier: "#{customer.id}-user",
                                              title: customer.card_name.present? ? customer.card_name : customer.email }
                                }.to_json) {}
    end

    # type: campaign_sent, new_payment, new_message_sms, new_message_messenger
    # payload is a hash with the data needed in the client. must include one of the types above
    def notifications(payload, merchant_id)
      merchant_id = merchant_id.to_s
      $pubnub.subscribe(channel: 'notifications_' + Rails.env + '_' + merchant_id) {}
      $pubnub.publish(channel: 'notifications_' + Rails.env + '_' + merchant_id,
                      message: payload.to_json) {}
    end

    def campaign_notification
      Time.zone = current_user.time_zone
      campaign_user_list = CampaignUserList.where("CAST(created_at as DATE) = ?",
                           Time.current.in_time_zone.strftime("%Y-%m-%d"))
      campaign_user_list.each do |list|
        list.campaign.campaign_lists.count
        campaign_time = list.campaign.date_time.strftime("%I:%M")
        { campaign_sent: "Your campaign scheduled for #{campaign_time} was sent"}
      end
    end
  end
end
