class RealtimeStreamService

  class << self

    # might need to redo how conv_ref is sent
    def messages(conversation, conv_ref, customer, msg)
      merchant_id = conversation.merchant_id.to_s
      $pubnub.publish(channel: 'messaging_' + Rails.env + '_' + merchant_id,
                      message: { type: 'new-message', conversation: conversation.conversation_hash,
                                 message: Conversation.message_hash(conversation, msg, conv_ref) })

      if conv_ref.source == "customer" && $redis_merchant_status.get(merchant_id) != 'online'
        
        customer_name = customer.present? ? customer.full_name : ((conversation.uid_type == 'fb_page') ? 'Messenger' : msg.from)
        profile_pic = User.profile_url_only(customer)

        notifications({ profile_pic: profile_pic, customer_name: customer_name, message: msg.text[0..15] + "...",
                        type: conv_ref.textable_type == 'Message' ? 'new_message_sms' : 'new_message_messenger' },
                        merchant_id)
      
        alert_obj = conversation.merchant.alert
        if alert_obj.try(:send_alert)
          options = { merchant: conversation.merchant, message_time: msg.created_at.strftime("%A, %l:%M%P"), 
                      message: msg.text, sender_profile_url: profile_pic, customer_name: customer_name }          

          # email alerts
          options[:sender_email] = customer.try(:email) || ""
          to = alert_obj.emails.map { |e| { "email" => e } }
          EmailingService.unread_message_notification(to, options)

          # sms alerts
          to = alert_obj.sms_numbers
          if alert_obj.include_sms && to.present?
            team = User.get_platform_acct_obj
            msg_to_send = "You have a new unread message from #{options[:sender_name]} on your #{Rails.application.secrets.app['name']} dashboard."
            to.each do |pn|
              pn = pn.gsub('+', '')
              customer = User.find_by(phone_number: pn)
              uid_type = customer ? 'user' : 'phone_number'
              uid = customer.try(:id) || pn
              Conversation.find_or_create_conversation_for_message_and_send_publish(team, customer, uid_type, uid, msg_to_send)          
            end
          end
        end
      end

      #Rails.logger.debug "DEBUG: and we are in RealtimeStreamService messages method"
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
                                })
    end

    # type: campaign_sent, new_payment, new_message_sms, new_message_messenger
    # payload is a hash with the data needed in the client. must include one of the types above
    def notifications(payload, merchant_id)
      $pubnub.publish(channel: 'notifications_' + Rails.env + '_' + merchant_id.to_s, message: payload)
    end

  end

end
