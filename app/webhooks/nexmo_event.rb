class NexmoEvent

  class << self

     def process_event(params)
      @param = params
      if @param
        save_message
      else
        # else part...
      end
     end

     # save both inbound and outbound message
     def save_message
      @message = Message.where(message_id: @param['messageId']).first_or_initialize
       @message.update(
          to: @param['to'],
          from: @param['msisdn'],
          message_timestamp: @param['message-timestamp'],
          message_price: @param['price'],
          status: @param['status'],
          error_code: @param['err-code'],
          user_id: get_user_id,
          user_id_to: get_merchant_id,
          text: @param['text']
      )
     end

     def get_user_id
       user = User.find_by(phone_number:  @param['to'])
       user.id if user
     end

     def get_merchant_id
       merchant = User.find_by(rhombus_number: @param['msisdn'])
       merchant.id if merchant
     end

   end

 end
