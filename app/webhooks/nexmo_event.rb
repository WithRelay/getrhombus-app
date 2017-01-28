class NexmoEvent

  class << self

    def process_event(params)
      @param = params
      @param['client-ref'].present? ? update_message : save_message
    end

    # save inbound
    def save_message
      merchant_id = get_merchant_id
      user_id = get_user_id

      @message = Message.create(
        to: @param[:to],
        from: @param[:msisdn],
        user_id: user_id,
        user_id_to: merchant_id,
        message_id: @param[:messageId],
        text: @param[:text].strip,
        num_segments: @param["concat-total"] || 1,
        message_timestamp: @param["message-timestamp"]
      )

      # create or add to existing conversation
      if user_id.present?
        uid, uid_type = user_id, 'user'
      else
        uid, uid_type = @param[:From].gsub('+', ''), 'phone_number'
      end
      Conversation.new.find_or_create_conversation_for_message(merchant_id, uid_type, uid, @message, true)
  
      # send to real time service
    end

    # save outbound delivery report
    def update_message
      Message.where(id: @param["client-ref"])
            .update_all(status: @param[status], message_price: @param[:price], 
              error_code: @param["err-code"], message_timestamp: @param['message-timestamp'])
    end

    private

      def get_user_id
        user = User.find_by(phone_number:  @param[:msisdn])
        user.id if user
      end

      def get_merchant_id
        merchant = User.find_by(rhombus_number: @param[:to])
        merchant.id if merchant
      end

  end

 end
