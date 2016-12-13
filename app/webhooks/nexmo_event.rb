class NexmoEvent

  class << self

   def process_event(params)
    @param = params
    save_message if @param[:messageId]
   end

   # save both inbound and outbound messages events
   def save_message
    @message = Message.where(message_id: @param[:messageId]).first_or_initialize
    update_message
   end

  def update_message
    @message.to = @param[:to]
    @message.from = @param[:msisdn]
    @message.message_timestamp = @param['message-timestamp']
    @message.user_id = get_user_id
    @message.user_id_to = get_merchant_id
    @message.text ||= @param[:text]
    @message.message_price = @param[:price]
    @message.status = @param[:status]
    @message.error_code = @param['err-code']
    @message.save
  end

   private

   def get_user_id
     user = User.find_by(phone_number:  @param[:to])
     user.id if user
   end

   def get_merchant_id
     merchant = User.find_by(rhombus_number: @param[:msisdn])
     merchant.id if merchant
   end

   end

 end
