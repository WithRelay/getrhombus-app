class NexmoEvent

  class << self

    def process_event(params, merchant)
      @params = params
      @merchant = merchant
      @params['client-ref'].present? ? update_message : save_message
    end

    # save inbound
    def save_message
      user = get_user

      @message = Message.create(
        to: @params[:to],
        from: @params[:msisdn],
        user_id: user.nil? ? nil : user.id,
        user_id_to: @merchant.id,
        message_id: @params[:messageId],
        text: @params[:text].strip,
        num_segments: @params["concat-total"] || 1,
        message_timestamp: @params["message-timestamp"]
      )

      # create or add to existing conversation
      if user.present?
        uid, uid_type = user.id, 'user'
      else
        uid, uid_type = @params[:From].gsub('+', ''), 'phone_number'
      end
      Conversation.find_or_create_conversation_for_message_and_publish(@merchant, user, uid_type, uid, @message, true)
    end

    # save outbound delivery report
    def update_message
      Message.where(id: @params["client-ref"])
            .update_all(status: @params[status], message_price: @params[:price], 
              error_code: @params["err-code"], message_timestamp: @params['message-timestamp'])
    end

    private

      def get_user
        User.find_by(phone_number:  @params[:msisdn])
      end

  end

 end
