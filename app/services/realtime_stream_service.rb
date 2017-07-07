class RealtimeStreamService

  class << self

    # might need to redo how conv_ref is sent
    # Sends a message to the given merchant's channel, provided user and merchant numbers
    def messages(conversation, conv_ref, merchant, customer, msg)
      merchant_id = conversation.merchant_id.to_s
      response = {}
      $pubnub.here_now(
        channels: ['messaging_' + Rails.env + '_' + merchant_id],
      )do |envelope|
        response = JSON.parse envelope.status[:server_response].body
      end
      unless response['uuids'].include? "uuid-#{merchant_id}"
        puts 'merchant offline'
      else
        puts 'merchant online'
      end
      # $pubnub.subscribe(channel: 'messaging_' + Rails.env + '_' + merchant_id) {}
      # check merchant_presence_on_channel if it returns false then send sms/message to the merchant
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
      campaign_recipients = CampaignRecipient.where("CAST(created_at as DATE) = ?",
                           Time.current.in_time_zone.strftime("%Y-%m-%d"))
      campaign_recipients.each do |list|
        list.campaign.campaign_lists.count
        campaign_time = list.campaign.date_time.strftime("%I:%M")
        { campaign_sent: "Your campaign scheduled for #{campaign_time} was sent"}
      end
    end

    def merchant_presence_on_channel(merchant_id)
      status = {}
      $pubnub.here_now(
        channel: 'messaging_' + Rails.env + '_' + merchant_id.to_s,
      ) do |envelope|
        status = envelope.status
      end
      response = JSON.parse status[:server_response].body
      merchant_uuid = "uuid-#{merchant_id}"
      response.uuids.include? merchant_uuid
    end
  end
end
