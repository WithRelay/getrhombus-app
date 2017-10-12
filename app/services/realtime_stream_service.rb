class RealtimeStreamService

  class << self

    # might need to redo how conv_ref is sent
    # Sends a message to the given merchant's channel, provided user and merchant numbers
    def messages(conversation, conv_ref, customer, msg, send_alert = false)
      merchant_id = conversation.merchant_id.to_s

      if send_alert && $redis_merchant_status.get(merchant_id) != 'online'
        alert_obj = conversation.merchant.alert
        if alert_obj.try(:send_alert)
          options = { merchant: conversation.merchant, message_time: msg.created_at.strftime("%A, %l:%M%P"), 
                      message: msg.text, sender_profile_url: User.profile_url_for_email(customer) }          

          if customer.present?        
            options[:sender_name] = customer.full_name 
            options[:sender_email] = customer.email
          else
            options[:sender_email] = ''
            options[:sender_name] = (conversation.uid_type == 'fb_page') ? 'Messenger' : msg.from)
          end
          
          # email alerts
          to = alert_obj.emails.map { |e| { "email" => e } }
          EmailingService.unread_message_notification(to, options)

          # sms alerts
          to = alert_obj.sms_numbers
          if alert_obj.include_sms && to.present?
            team = User.get_platform_acct_obj
            msg_to_send = "You have a new unread message from #{customer} on your #{Rails.application.secrets.app['name']} dashboard."
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

      # will not subscribing and publishing cause all the messages to be republish upon subscribe in view???
      # it will cause duplicate errors in angular
      #$pubnub.subscribe(channel: 'messaging_' + Rails.env + '_' + merchant_id)  
      $pubnub.publish(channel: 'messaging_' + Rails.env + '_' + merchant_id,
                      message: { type: 'new-message',
                                 message: Conversation.message_hash(conversation, msg, conv_ref),
                                 conversation: conversation.conversation_hash })
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
      #$pubnub.subscribe(channel: 'notifications_' + Rails.env + '_' + merchant_id.to_s)
      $pubnub.publish(channel: 'notifications_' + Rails.env + '_' + merchant_id.to_s, message: payload)
    end

    ### this isnt being used???????????????
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

  end
end
