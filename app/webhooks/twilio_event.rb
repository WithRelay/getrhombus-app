class TwilioEvent

  class << self

     def process_event(params)
      @param = params
      if @param[:MessageStatus] == 'sent'
        save_twilio_message
      elsif @param[:MessageStatus] == 'delivered'
        update_message_status
      else
        # else part
      end
    end                            

    def save_twilio_message
      # fetch message data
      @data = TextingService.fetch_message_details(@param[:MessageSid])
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
        # transaction_id: @param[],
        message_id: @param[:MessageSid],
        text: @data.body,
        # unread: @param[],
        num_segments: @data.num_segments,
        price_unit: @data.price_unit,
        # hashtag_id: @param[],
      )
      # save media/mms if present
      save_media if @data.num_media.to_i > 0
    end

    def update_message_status
      message = Message.find_by(message_id: @param[:MessageSid])
      message.update(status: @param[:MessageStatus])
    end

    def get_user_id
      user = User.find_by(phone_number: @param[:To].gsub('+', ''))
      user.id if user
    end

    def get_merchant_id
      merchant = User.find_by(rhombus_number: @param[:From].gsub('+', ''))
      merchant.id if merchant
    end

    def save_media
      # media_lists = @data.media.list
      # media_lists.each do |media|
      #   url = TwilioService.retrieve_media_url(media.uri)
      #   if %w{image/jpeg image/png image/gif}.include?(media.content_type)
      #     image = @message.images.new
      #     image.avatar_from_remote_url(url)
      #   end
      # end
    end

  end
end
