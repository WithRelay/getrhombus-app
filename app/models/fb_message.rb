class FbMessage < ActiveRecord::Base
  # for conversation
  has_one :conversation_ref, as: :textable, dependent: :destroy
  has_one :conversation, through: :conversation_refs

  belongs_to :fb_page

  # for image table relation
  has_many :image_refs, as: :imageable, dependent: :destroy
  has_many :images, through: :image_refs

  validates :message_id, uniqueness: true, allow_nil: true

  has_one :notification_log, class_name: 'NotificationLog', foreign_key: 'channel_id'

  # For sending and saving all outbound text messages
  def send_and_save_message(merchant, user, page_access_token, recipient_id, message, unread, media_url)
    begin
      # save message before sending
      user = (user.present?) ? user.id : nil

      if response = FacebookMessengerService.send_text_message(page_access_token, recipient_id, message)
        response = JSON.parse(response)
        self.update_attributes(user_id: merchant.id, user_id_to: user, text: message, message_id: response['message_id'], to: response['recipient_id'], unread: unread)

        if media_url.present?
          attachment_type = "image" #now we only support image file attachment
          FacebookMessengerService.send_attachment(page_access_token, recipient_id, attachment_type, media_url)
        end
        true
      else
        self.notification_log = NotificationLog.create(notify_type: 'message sending failed', channel: 'facebook messenger', reason: 'Message sending has been failed.')
        false
      end
    rescue StandardError => err
      false
    end
  end
end
