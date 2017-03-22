class TwilioEvent

  class << self

    def process_event(params, merchant)
      @params = params
      @merchant = merchant
      @data = TextingService.fetch_message_details(@params[:MessageSid])         # fetch additional message data
      if (@data && @data.direction == "outbound-api") || (!@data && !["received", "receiving"].include?(@params[:SmsStatus]))
        update_sent_message
      elsif @params[:SmsStatus] == 'received'
        save_received_message
      end
    end

    private

    # when message is sent from rhombus
    def update_sent_message
      Message.where(message_id: @params[:MessageSid])
        .update_all(message_timestamp: @data.date_sent,
          message_price: @data.price, status: @params[:MessageStatus], error_text: @data.error_message,
          error_code: @data.error_code, num_segments: @data.num_segments, price_unit: @data.price_unit)
    end

    # when message is sent to rhombus
    def save_received_message
      begin
        @phone_number = @params[:From].gsub('+', '')
        user = get_user
        @message_id = @params[:MessageSid]
        @message = Message.create(
          to: @params[:To].gsub('+', ''),
          from: @phone_number,
          status: @params[:SmsStatus],
          user_id: user.nil? ? nil : user.id,
          user_id_to: @merchant.id,
          message_id: @message_id,
          text: @params[:Body].strip,
          num_segments: @params[:NumSegments],
          num_media: @params[:NumMedia],
          price_unit: @data.price_unit,
          message_timestamp: @data.date_updated,
          message_price: @data.price,
          error_text: @data.error_message,
          error_code: @data.error_code
        )

        # save user info on twilio_number_data
        add_or_update_twilio_number_data
        # save media/mms if present
        save_media if @params[:NumMedia].to_i > 0

        # create or add to existing conversation, send to real time service
        if user.present?
          uid, uid_type = user.id, 'user'
        else
          uid, uid_type = @phone_number, 'phone_number'
          OpenCnamData.find_record_or_get_intelligence_data(@phone_number)
        end

        Conversation.find_or_create_conversation_for_message_and_publish(@merchant, user, uid_type, uid, @message, true)
        MessageParser.new.process_message(@merchant, user, @message, 'Message')

      rescue ActiveRecord::RecordNotUnique
      end
    end

    def add_or_update_twilio_number_data
      TwilioNumberData.add_or_update_twilio_number_data(
        @message.from,
        @params[:FromCity],
        @params[:FromState],
        @params[:FromZip],
        @params[:FromCountry]
      )
    end

    def get_user
      User.find_by(phone_number:  @phone_number)
    end

    def save_media
      num_media = @params[:NumMedia].to_i
      num_media.times do |i|
        media_url = @params["MediaUrl#{i}"]
        if %w{image/jpeg image/png image/gif}.include?( @params["MediaContentType#{i}"])
          image = @message.images.new
          image.avatar_for_twilio_media(media_url)
        end
      end
    end

  end
end
