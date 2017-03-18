class Message < ActiveRecord::Base

  # for conversation
  has_many :conversation_refs, as: :textable, dependent: :destroy
  has_many :conversations, through: :conversation_refs
  
  belongs_to :txn, :foreign_key => :transaction_id, :class_name => :Transaction
  belongs_to :hashtag

  # for image table relation
  has_many :image_refs, as: :imageable, dependent: :destroy
  has_many :images, through: :image_refs

  has_one :notification_log, class_name: 'NotificationLog', foreign_key: 'channel_id'
  validates :message_id, uniqueness: true, allow_nil: true

  belongs_to :user

  # For sending and saving all outbound text messages
  def send_and_save_message(merchant, user, from, to, message, media_ary = [])
    begin
      # save message before sending
      user = (user.present?) ? user.id : nil
      self.update_attributes(user_id: merchant.id, user_id_to: user, from: from, to: to, text: message)

      if true #merchant.rn_type.present?      # this is twilio
        if response = TextingService.send_sms(from, to, message, media_ary)
          self.update_attributes(status: response.status, message_id: response.sid, message_timestamp: response.date_updated, message_price: response.price,
                error_code: response.error_code, error_text: response.error_message, price_unit: response.price_unit, num_segments: response.num_segments,
                num_media: response.num_media)
        else
          Notification.text_failure_notification(response, from, to, message).deliver_now                         # Notify team of failure
          false
        end
      else
        response = TextingService.send_sms_nexmo(from, to, message, self.id)
        if response && response.code == 200 && response["messages"].first["status"] == "0"
            self.update_attributes(status: response['messages'].first['status'], message_id: response['messages'].first['message-id'],
                message_price: response['messages'].first['message-price'], num_segments: response['message-count'],
                error_text: response["error-text"])
        else
          Notification.text_failure_notification(response["messages"].first, from, to, message).deliver_now               # Notify team of failure
          false
        end
      end

    rescue StandardError => err
      false
    end
  end

end