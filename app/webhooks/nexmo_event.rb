class NexmoEvent

  class << self

    def process_event(params)
      @param = params
      @param['client-ref'].present? ? update_message : save_message
    end

    # save inbound
    def save_message
      merchant = get_merchant
      user = get_user

      @message = Message.create(
        to: @param[:to],
        from: @param[:msisdn],
        user_id: user.nil? ? nil : user.id,
        user_id_to: merchant.id,
        message_id: @param[:messageId],
        text: @param[:text].strip,
        num_segments: @param["concat-total"] || 1,
        message_timestamp: @param["message-timestamp"]
      )

      # create or add to existing conversation
      if user.present?
        uid, uid_type = user.id, 'user'
      else
        uid, uid_type = @param[:From].gsub('+', ''), 'phone_number'
      end
      Conversation.find_or_create_conversation_for_message_and_publish(merchant, user, uid_type, uid, @message, true)
    end

    # save outbound delivery report
    def update_message
      Message.where(id: @param["client-ref"])
            .update_all(status: @param[status], message_price: @param[:price], 
              error_code: @param["err-code"], message_timestamp: @param['message-timestamp'])
    end

    private

      def get_user
        User.find_by(phone_number:  @param[:msisdn])
      end

      def get_merchant
        User.find_by(rhombus_number: @param[:to])
      end

  end

 end
