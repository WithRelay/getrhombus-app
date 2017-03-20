class RealtimeStreamService

  class << self
    

=begin
    # Sends a message to the given merchant's channel, provided user and merchant numbers
    def send_message_via_number(user_number, merchant_number, message, message_ts, is_merchant_message = false)
      merchant = User.find_by_rhombus_number(merchant_number)
      
      if !merchant.blank?
        $pubnub.subscribe(
          :channel  => 'messaging_' + Rails.env + '_' + merchant.id.to_s
        ) {}
        
        user = User.find_by_phone_number(user_number)
        user_level = is_merchant_message ? 1 : 0
        
        $pubnub.publish(
          :channel  => 'messaging_' + Rails.env + '_' + merchant.id.to_s,
          :message => Hash[
            'user_number' => user_number,
            'first_name' => user.blank? ? user_number : user.first_name,
            'last_name' => user.blank? ? '' : user.last_name,
            'email' => user.blank? ? '' : user.email,
            'user_level' => user_level,
            'image_url' => user_level == 0 ? ActionController::Base.helpers.asset_path('user_icon_50x50.png') : ActionController::Base.helpers.asset_path('rhombus_icon_50x50.png'),
            'message' => message,
            'ts_day_of_the_week' => message_ts.strftime('%A'),
            'ts_time' => message_ts.strftime('%l:%M %P'),
            'ts_int' => message_ts.to_i,
            'unread' => false
          ].to_json
        ) {}
      end
    end
=end

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