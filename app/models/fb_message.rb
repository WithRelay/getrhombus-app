# Save messages from facebook
class FbMessage < ActiveRecord::Base
  # for conversation
  has_one :conversation_ref, as: :textable, dependent: :destroy
  has_one :conversation, through: :conversation_refs

  belongs_to :txn, :foreign_key => :transaction_id, :class_name => :Transaction
  belongs_to :hashtag

  # for image table relation
  has_many :image_refs, as: :imageable, dependent: :destroy
  has_many :images, through: :image_refs

  validates :message_id, uniqueness: true, allow_nil: true

  belongs_to :user
  belongs_to :fb_page

  # For sending and saving all outbound text message
  # from = merchant page_access_token, to = recipient_id
  def send_and_save_message(merchant, user, from, to, message, media_url)
    begin
      # save message before sending
      user = user.present? ? user.id : nil
      self.update_attributes(
        user_id: merchant.id,
        user_id_to: user,
        from: from,
        to: to,
        text: message
      )

      if response = FacebookMessengerService.send_text_message(from, to, message)
        self.update_attributes(message_id: JSON.parse(response)['message_id'])

        if media_url.present?
          # now we only support image file attachment
          attachment_type = 'image'
          FacebookMessengerService.send_attachment(from, to, attachment_type, media_url)
        end
        true
      else
        # Notify team of failure
        Notification.text_failure_notification(response, from, to, message).deliver_now
        false
      end
    rescue StandardError => err
      false
    end
  end
end
