class Message < ActiveRecord::Base

  # for conversation
  has_many :conversation_refs, as: :textable, dependent: :destroy
  has_many :conversations, through: :conversation_refs

  belongs_to :txn, :foreign_key => :transaction_id, :class_name => :Transaction
  belongs_to :hashtag

  # for image table relation
  has_many :image_refs, as: :imageable, dependent: :destroy
  has_many :images, through: :image_refs

  validates :message_id, uniqueness: true, allow_nil: true

  belongs_to :user

  # For sending and saving all outbound text messages
  def send_and_save_message(merchant, user, from, to, message, media_ary = [])
    begin
      # save message before sending
      user = user.try(:id)
      self.update_attributes(user_id: merchant.id, user_id_to: user, from: from, to: to, text: message)
      sms_price = merchant.sms_fee.outbound_sms

      if merchant.rn_type.present?      # twilio
        response = TextingService.send_sms(from, to, message, media_ary)
        if response.first
          response = response.second
          num_segments = response.num_segments.to_i
          price = media_ary.blank? ? sms_price : merchant.sms_fee.outbound_mms
          #merchant.deduct_from_account_balance(price * num_segments)
          self.update_attributes(status: response.status, message_id: response.sid, message_timestamp: response.date_updated, 
                                  message_price: response.price, error_code: response.error_code, error_text: response.error_message,
                                  price_unit: response.price_unit, num_segments: num_segments, num_media: response.num_media, relay_price: price)
        else
          ExceptionNotifier.notify_exception(StandardError.new, data: { message: "From send_and_save_message, unable to send message", from: from, to: to, text: message, env: Rails.env, response: response })
          false
        end
      elsif merchant.fn_subscriber_id.present?   #  fibernetics
        response = TextingService.send_sms_fibernetics(from, to, message, merchant.fn_subscriber_id)
        if response && response.code == 200 && response['response']['status'] == 'OK'
          num_segments = Message.num_of_segments(message)
          merchant.deduct_from_account_balance(sms_price * num_segments)
          self.update_attributes(status: "OK", num_segments: num_segments, relay_price: sms_price)          
        else
          ExceptionNotifier.notify_exception(StandardError.new, data: { message: "From send_and_save_message, unable to send message", from: from, to: to, text: message, env: Rails.env, response: response })
          false
        end
      else # nexmo
        response = TextingService.send_sms_nexmo(from, to, message, self.id)
        if response.first && response.second.code == 200 && response.second["messages"].first["status"] == "0"
          response = response.second
          num_segments = response['message-count'].to_i
          #merchant.deduct_from_account_balance(sms_price * num_segments)
          self.update_attributes(status: response['messages'].first['status'], num_segments: num_segments, relay_price: sms_price,
                                  message_id: response['messages'].first['message-id'], error_text: response["error-text"],
                                  message_price: response['messages'].first['message-price'])
        else
          ExceptionNotifier.notify_exception(StandardError.new, data: { message: "From send_and_save_message, unable to send message", from: from, to: to, text: message, env: Rails.env, response: response })
          false
        end
      end
    rescue StandardError => err
      ExceptionNotifier.notify_exception(err, data: { message: "From send_and_save_message, unable to send message", from: from, to: to, text: message, env: Rails.env })
      false
    end
  end

  def self.num_of_segments(msg)
    (msg.bytesize/140.to_f).ceil
  end

  def self.relay_tip1
    "Relay tips: We've improved your payment experience with Relay by replacing the $ sign with a + tag. You can now text +10 instead of $10 to make a payment to a local business or non-profit."
  end

  def self.relay_tip2
    'Relay tips: With the + tag, you can now place the amount anywhere in the message. Ex. "pizza & broccoli +8 yay!" instead of "$8 pizza & broccoli'
  end

  def self.api_send(msg=nil)
    begin
      msg = msg.present? ? msg : 'Trios number test'
      webhook_url: '<redacted_webhook_url>'
      body = { key: 'wdJobH3wLOafkjPn3Yn5TQtt', secret: 'XyQjmW19Jf3cCNyesqEHmQtt', to: '<redacted_phone_number>',<redacted_phone_number>", body: msg }
      options = { body: body.to_json, headers: { 'Content-Type' => 'application/json' } }
      HTTParty.post(webhook_url, options)
    rescue StandardError => exception
      ExceptionNotifier.notify_exception(exception, data: { message: "In post_message_for_api_user", env: Rails.env, options: options })
    end
  end

  def self.api_send_local
    begin
      webhook_url: '<redacted_webhook_url>'
      body = { key: 'QBy6xmWxUkvCndzJmw1LcAtt', secret: '80O4jUQVdYSP3zrnPyYMMgtt', to: '<redacted_phone_number>',<redacted_phone_number>", body: "Api send test" }
      options = { body: body.to_json, headers: { 'Content-Type' => 'application/json' } }
      HTTParty.post(webhook_url, options)
    rescue StandardError => exception
      ExceptionNotifier.notify_exception(exception, data: { message: "In post_message_for_api_user local", options: options })
    end
  end

end