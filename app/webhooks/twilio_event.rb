class TwilioEvent

  class << self

     def process_event(params)
      @param = params
      # fetch message additional data
      @data = TextingService.fetch_message_details(@param[:MessageSid])
      if @param[:MessageStatus] == 'sent'
        save_sent_message
      elsif @param[:SmsStatus] == 'received'
        save_received_message
      elsif @param[:MessageStatus] == 'delivered'
        update_message_status
      end
    end                            

    private

    # when message send from rhombus
    def save_sent_message
      merchant_id = get_merchant_id(@param[:From])
      user_id = get_user_id(@param[:To])
      
      Message.create(
        to: @param[:To].gsub('+', ''),
        from: @param[:From].gsub('+', ''),
        message_timestamp: @data.date_sent,
        message_price: @data.price,
        status: @param[:MessageStatus],
        error_text: @data.error_message,
        error_code: @data.error_code,
        user_id: merchant_id,
        user_id_to: user_id,
        message_id: @param[:MessageSid],
        text: @data.body.strip,
        num_segments: @data.num_segments,
        price_unit: @data.price_unit
      )
    end

    # when message send to rhombus
    def save_received_message
      merchant_id = get_merchant_id(@param[:To])
      user_id = get_user_id(@param[:From])

      if user_id.present?
        uid, uid_type = user_id, 'user'
      else
        uid, uid_type = @param[:From].gsub('+', ''), 'phone_number'
      end

      @message = Message.create(
        to: @param[:To].gsub('+', ''),
        from: @param[:From].gsub('+', ''),
        status: @param[:SmsStatus],
        user_id: get_user_id,
        user_id_to: get_merchant_id,
        message_id: @param[:MessageSid],
        text: @param[:Body].strip,
        num_segments: @param[:NumSegments],
        price_unit: @data.price_unit,
        message_timestamp: @data.date_sent,
        message_price: @data.price,
        error_text: @data.error_message,
        error_code: @data.error_code
      )

      # save user info on twilio_number_data
      add_or_update_twilio_number_data

      # create or add to existing conversation
      Conversation.new.find_or_create_conversation_for_message(merchant_id, uid_type, uid, @message, true)
  
      # save media/mms if present
      save_media if @param[:NumMedia].to_i > 0
      @message.save!
    end

    def add_or_update_twilio_number_data
      TwilioNumberData.add_or_update_twilio_number_data(
        @message[:From],
        @message[:FromCity],
        @message[:FromState],
        @message[:FromZip],
        @message[:FromCountry]
      ) 
    end

    def update_message_status
      message = Message.find_by(message_id: @param[:MessageSid])
      message.update(status: @param[:MessageStatus])
    end

    def get_user_id(num)
      user = User.find_by(phone_number:  num.gsub('+', ''))
      user.id if user
    end

    def get_merchant_id(num)
      merchant = User.find_by(rhombus_number: num.gsub('+', ''))
      merchant.id if merchant
    end

    def save_media
      num_media = @param[:NumMedia].to_i
      num_media.times do |i|
        media_url = @param["MediaUrl#{i}"]
        if %w{image/jpeg image/png image/gif}.include?( @param["MediaContentType#{i}"])
          image = @message.images.new
          image.avatar_for_twilio_media(media_url)
        end
      end
    end

  end
end
