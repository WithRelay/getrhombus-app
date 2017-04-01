class NexmoEvent

  class << self

    def process_event(params, merchant)
      @params = params
      @merchant = merchant
      @params['client-ref'].present? ? update_message : save_message
    end

    # save inbound
    def save_message
      begin
        num_segments = @params["concat-total"].present? ? @params["concat-total"].to_i : 1

        user = get_user
        @message_id = @params[:messageId]
        @message = Message.create(
          to: @params[:to],
          from: @params[:msisdn],
          user_id: user.nil? ? nil : user.id,
          user_id_to: @merchant.id,
          message_id: @message_id,
          text: @params[:text].strip,
          num_segments: num_segments,
          message_timestamp: @params["message-timestamp"]
          relay_price: SMS_PRICE_RECEIVED
        )

        # create or add to existing conversation
        if user.present?
          uid, uid_type = user.id, 'user'
        else
          uid, uid_type = @params[:msisdn], 'phone_number'
          OpenCnamData.find_record_or_get_intelligence_data(@params[:msisdn])
        end
        
        Conversation.find_or_create_conversation_for_message_and_publish(@merchant, user, uid_type, uid, @message, true)
        @merchant.away_message.check_office_hours(@merchant, user, uid_type, uid, "Message")
        @merchant.update_account_balance(SMS_PRICE_RECEIVED * num_segments)
        MessageParser.new.process_message(@merchant, user, @message, 'Message')

      rescue ActiveRecord::RecordNotUnique
      end
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
