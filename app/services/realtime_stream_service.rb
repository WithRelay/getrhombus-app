class RealtimeStreamService

  class << self

    # might need to redo how conv_ref is sent
    # Sends a message to the given merchant's channel, provided user and merchant numbers
    def messages(conversation, conv_ref, customer, msg)
      logger.info('and we are in messagesasdsad')
      merchant_id = conversation.merchant_id.to_s
      if $redis_merchant_status.get(merchant_id) != 'online'
        puts 'merchant offline'
        # EmailingService.send_unread_message_alert({
        #   pluralize_msg: '',
        #   unread_count: 1,
        #   customer_first_name: customer.first_name      ########## remove thiss??????????? ask edwin
        # })
      end

      # will not subscribing and publishing cause all the messages to be republish upon subscribe in view???
      # it will cause duplicate errors in angular
      #$pubnub.subscribe(channel: 'messaging_' + Rails.env + '_' + merchant_id)  
      $pubnub.publish(channel: 'messaging_' + Rails.env + '_' + merchant_id,
                      message: { type: 'new-message',
                                 message: Conversation.message_hash(conversation, msg, conv_ref),
                                 conversation: conversation.conversation_hash })
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
