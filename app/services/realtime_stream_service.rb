class RealtimeStreamService

  class << self

    # might need to redo how conv_ref is sent
    # Sends a message to the given merchant's channel, provided user and merchant numbers
    def messages(conversation, conv_ref, merchant, customer, msg)
      merchant_id = conversation.merchant_id.to_s
      $pubnub.subscribe(channel: 'messaging_' + Rails.env + '_' + merchant_id) {}
      $pubnub.publish(channel: 'messaging_' + Rails.env + '_' + merchant_id,
                      message: { message: Conversation.message_hash(conversation, msg, conv_ref, customer), conversation: conversation.conversation_hash }.to_json) {}
    end

    # type: campaign_sent, new_payment, new_message_sms, new_message_messenger
    # payload is a hash with the data needed in the client. must include one of the types above
    def notifications(payload, merchant_id)
      merchant_id = merchant_id.to_s
      $pubnub.subscribe(channel: 'notifications_' + Rails.env + '_' + merchant_id) {}
      $pubnub.publish(channel: 'notifications_' + Rails.env + '_' + merchant_id,
                      message: payload.to_json) {}
    end

  end
  
end