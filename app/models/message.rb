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
      user = (user.present?) ? user.id : nil
      self.update_attributes(user_id: merchant.id, user_id_to: user, from: from, to: to, text: message)

      if true #merchant.rn_type.present?      # this is twilio
        response = TextingService.send_sms(from, to, message, media_ary)
        if response.first
          response = response.second
          num_segments = response.num_segments.to_i
          price = (media_ary.blank?) ? (SMS_PRICE_SENT * num_segments) : MMS_PRICE_SENT
          merchant.deduct_from_account_balance(price)
          self.update_attributes(status: response.status, message_id: response.sid,
                                  message_timestamp: response.date_updated, message_price: response.price,
                                  error_code: response.error_code, error_text: response.error_message,
                                  price_unit: response.price_unit, num_segments: num_segments,
                                  num_media: response.num_media, relay_price: price)
        else
          Notification.text_failure_notification(response.second, from, to, message).deliver_now                         # Notify team of failure
          false
        end
      else
        response = TextingService.send_sms_nexmo(from, to, message, self.id)
        if response.first && response.second.code == 200 && response.second["messages"].first["status"] == "0"
          response = response.second
          num_segments = response['message-count'].to_i
          merchant.deduct_from_account_balance(SMS_PRICE_SENT * num_segments)
          self.update_attributes(status: response['messages'].first['status'], num_segments: num_segments,
                                  message_id: response['messages'].first['message-id'],
                                  message_price: response['messages'].first['message-price'],
                                  error_text: response["error-text"], relay_price: SMS_PRICE_SENT)
        else
          Notification.text_failure_notification(response.second, from, to, message).deliver_now               # Notify team of failure
          false
        end
      end
    rescue StandardError => err
      puts err.inspect
      puts 'eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeerrrrrrrrrrrrrrrrrrrrrrrrrr'
      false
    end
  end

end