class TwilioEvent

  class << self

    def process_event(params)
      @param = params
      @data = TextingService.fetch_message_details(@param[:MessageSid])         # fetch additional message data

      if (@data && @data.direction == "outbound-api") || (!@data && !["received", "receiving"].include?(@param[:SmsStatus]))
        update_sent_message
      elsif @param[:SmsStatus] == 'received' 
        save_received_message
      end
    end                            

    private

    # when message is sent from rhombus
    def update_sent_message       
      Message.where(message_id: @param[:MessageSid])
        .update_all(message_timestamp: @data.date_sent, 
          message_price: @data.price, status: @param[:MessageStatus], error_text: @data.error_message,
          error_code: @data.error_code, num_segments: @data.num_segments, price_unit: @data.price_unit)
    end

    # when message is sent to rhombus
    def save_received_message
      merchant = get_merchant
      user = get_user

      @message = Message.create(
        to: @param[:To].gsub('+', ''),
        from: @param[:From].gsub('+', ''),
        status: @param[:SmsStatus],
        user_id: user.nil? ? nil : user.id,
        user_id_to: merchant.id,
        message_id: @param[:MessageSid],
        text: @param[:Body].strip,
        num_segments: @param[:NumSegments],
        num_media: @param[:NumMedia],
        price_unit: @data.price_unit,
        message_timestamp: @data.date_updated,
        message_price: @data.price,
        error_text: @data.error_message,
        error_code: @data.error_code
      )

      # save user info on twilio_number_data
      add_or_update_twilio_number_data
  
      # save media/mms if present
      save_media if @param[:NumMedia].to_i > 0
      @message.save

      # create or add to existing conversation, send to real time service
      if user.present?
        uid, uid_type = user.id, 'user'
      else
        uid, uid_type = @param[:From].gsub('+', ''), 'phone_number'
      end

      Conversation.find_or_create_conversation_for_message_and_publish(merchant, user, uid_type, uid, @message, true)
      MessageParser.new.process_message(merchant, user, @message, 'Message')
    end

    def add_or_update_twilio_number_data
      TwilioNumberData.add_or_update_twilio_number_data(
        @message.from,
        @param[:FromCity],
        @param[:FromState],
        @param[:FromZip],
        @param[:FromCountry]
      ) 
    end

    def get_user
      User.find_by(phone_number:  @param[:From].gsub('+', ''))
    end

    def get_merchant
      User.find_by(rhombus_number: @param[:To].gsub('+', ''))
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
