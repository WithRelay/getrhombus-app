class NexmoEvent

  def process_event(params, merchant)
    @params = params
    @merchant = merchant
    @params['client-ref'].present? ? update_message : save_message
  end

  # save inbound
  def save_message
    begin
      num_segments = @params["concat-total"].present? ? @params["concat-total"].to_i : 1
      sms_price = @merchant.sms_fee.inbound_sms

      #num_media = @params[:image_url].present? ? 1 : 0

      user = get_user
      @message_id = @params[:messageId]
      @message = Message.create!(
        to: @params[:to],
        from: @params[:msisdn],
        user_id: user.try(:id),
        user_id_to: @merchant.id,
        message_id: @message_id,
        text: @params[:text].try(:strip),
        #num_media: num_media,
        num_segments: num_segments,
        message_timestamp: @params["message-timestamp"],
        relay_price: sms_price
      )

      #save_media if num_media > 0

      # create or add to existing conversation
      if user.present?
        uid, uid_type = user.id, 'user'
        MerchantCustomer.add_or_update_merchant_customer(@merchant, user)
      else
        uid, uid_type = @params[:msisdn], 'phone_number'
        MerchantContact.add_or_update_merchant_contact(@merchant.id, uid, uid_type)
        #OpenCnamData.find_record_or_get_intelligence_data(uid)
      end

      Conversation.find_or_create_conversation_for_message_and_publish(@merchant, user, uid_type, uid, @message, true)
      @merchant.away_message.check_office_hours(@merchant, user, uid_type, uid, "Message")
      MessageParser.new.process_message(@merchant, user, uid, uid_type, @message, 'Message')
      #@merchant.deduct_from_account_balance(sms_price * num_segments)
      RulesEngineJob.perform_later(@message.id) if @merchant.rules.present?

    rescue ActiveRecord::RecordNotUnique => exception
      ExceptionNotifier.notify_exception(exception, data: { message: "In save_message record not unique", env: Rails.env, params: @params })
    rescue ActiveRecord::RecordInvalid => exception
      ExceptionNotifier.notify_exception(exception, data: { message: "In save_message record invalid", env: Rails.env, params: @params })
    rescue StandardError => exception
      ExceptionNotifier.notify_exception(exception, data: { message: "In save_message", env: Rails.env, params: @params })
    end
  end

  def save_media
    images_ary = []
    image = Image.new
    image.avatar_for_twilio_media(media_url)
    images_ary << image
    @message.images = images_ary if images_ary.present?
  end

  # save outbound delivery report
  def update_message
    Message.where(id: @params["client-ref"])
           .update_all(status: @params[:status], message_price: @params[:price],
                       error_code: @params["err-code"], message_timestamp: @params['message-timestamp'])
  end

  private

    def get_user
      User.find_by(phone_number: @params[:msisdn])
    end


end
