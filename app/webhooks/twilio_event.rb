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
      else
        # else part goes here
      end
    end                            

    # when message send from rhombus
    def save_sent_message
      @message = Message.create(
        to: @param[:To],
        from: @param[:From],
        message_timestamp: @data.date_sent,
        message_price: @data.price,
        status: @param[:MessageStatus],
        error_text: @data.error_message,
        error_code: @data.error_code,
        user_id: get_user_id,
        user_id_to: get_merchant_id,
        message_id: @param[:MessageSid],
        text: @data.body,
        num_segments: @data.num_segments,
        price_unit: @data.price_unit
      )
    end

    # when message send to rhombus
    def save_received_message
      @message = Message.create(
        to: @param[:To],
        from: @param[:From],
        status: @param[:SmsStatus],
        user_id: get_user_id,
        user_id_to: get_merchant_id,
        message_id: @param[:MessageSid],
        text: @param[:Body],
        num_segments: @param[:NumSegments],
        price_unit: @data.price_unit,
        message_timestamp: @data.date_sent,
        message_price: @data.price,
        error_text: @data.error_message,
        error_code: @data.error_code
      )
      # save media/mms if present
      save_media if @param[:NumMedia].to_i > 0
      @message.save!
    end

    def update_message_status
      message = Message.find_by(message_id: @param[:MessageSid])
      message.update(status: @param[:MessageStatus])
    end

    def get_user_id
      user = User.find_by(phone_number:  @param[:To][1..-1])
      user.id if user
    end

    def get_merchant_id
      merchant = User.find_by(rhombus_number: @param[:From][1..-1])
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
