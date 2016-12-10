class Message < ActiveRecord::Base

  belongs_to :txn, :foreign_key => :transaction_id, :class_name => :Transaction
  belongs_to :hashtag
  # for image table relation
  has_many :image_refs, as: :imageable, dependent: :destroy
  has_many :images, through: :image_refs
  # for conversation
  has_many :conversation_refs, as: :textable, dependent: :destroy
  has_many :conversations, through: :conversation_refs

  has_many :notification_logs, as: :notifiable
  
  # belongs_to :user, counter_cache: true
  # For sending and saving all outbound text messages

  # combine into one method with below
  def self.send_and_save_message(from, to, message, media_ary = [])
    begin
      msg = Message.new
      msg.update_attributes(from: from, to: to, text: message, unread: false)
      if response = TextingService.send_sms(from, to, message, media_ary)
        msg.update_attributes(status: response.status, message_id: response.sid, message_timestamp: response.date_updated, message_price: response.price,
              error_code: response.error_code, error_text: response.error_message, price_unit: response.price_unit, num_segments: response.num_segments)
      else
        Notification.text_failure_notification(response, from, to, message).deliver_now                         # Notify team of failure
        false
      end
    rescue StandardError => err
      false
    end
  end

  # combine into one method with above
  def self.send_and_save_message_nexmo(from, to, message)
    begin
      # save the outbound message
      msg = Message.new
      msg.update_attributes(from: from, to: to, text: message, unread: false)
      response = TextingService.send_sms_nexmo(from, to, message)

      if response && response.code == 200 && response["messages"].first["status"] == "0"
          msg.update_attributes(status: response['messages'].first['status'], message_id: response['messages'].first['message-id'],
              message_price: response['messages'].first['message-price'], num_segments: response['message-count'])
      else
        Notification.text_failure_notification(response["messages"].first, from, to, message).deliver_now               # Notify team of failure
        false
      end
    rescue StandardError => err
        false
    end
  end

  # Returns hash with the last "num_messages" messages that the given user has sent to the given merchant
  def self.get_user_messages_by_merchant(user_number, merchant_id, num_messages)
    messages = Message.includes(:images)
                                        .select('`messages`.`user_id`,`messages`.`text`,`messages`.`unread`,`messages`.`created_at`,`users`.`user_level`')#, `messages`.`image_id`')
                        .joins('LEFT JOIN `users` ON (`users`.`id` = `messages`.`user_id`)')
                        .where('(`messages`.`from` = ? AND `messages`.`user_id_to` = ?) OR (`messages`.`user_id` = ? AND `messages`.`to` = ?)', user_number, merchant_id, merchant_id, user_number)
                        .order('`messages`.`created_at` DESC').limit(num_messages)
    latest_messages = Array.new
    messages.reverse.each do |message|
      latest_messages.push({
        :user_number => message.user_id,
        :user_level => message.user_level.blank? ? 0 : message.user_level,
        :profile_image => (message.user_level.blank? || (message.user_level == 0)) ? ActionController::Base.helpers.asset_path('user_icon_50x50.png') : ActionController::Base.helpers.asset_path('rhombus_icon_50x50.png'),
        :text => (message.text) ? message.text : nil,
        :ts_day_of_the_week => message.created_at.strftime('%A'),
        :ts_time => message.created_at.strftime('%l:%M %P'),
        :unread => message.unread,
        # return small version here??
        #:image_url => message.image_id? ? message.image.avatar.url : nil
      })
    end
    latest_messages
  end

  # Marks all user messages sent to a merchant as read
  def self.mark_user_messages_for_merchant_as_read(user_number, merchant_id)
    Message.where('`from` = ? AND `user_id_to` = ? AND `unread` = ?', user_number, merchant_id, true).update_all(unread: false)
  end

end
