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
  def send_and_save_message(merchant, user, from, to, message, media_urls = [])
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

        if media_urls.present?
          # now we only support image file attachment
          attachment_type = 'image'
          media_urls.each{ |url| FacebookMessengerService.send_attachment(from, to, attachment_type, url) }
        end
        true
      else
        ExceptionNotifier.notify_exception(StandardError.new, data: { message: "From FbMessage.rb send_and_save_message, unable to send message", from: from, to: to, text: message, env: Rails.env, response: response })
        false
      end
    rescue StandardError => err
      false
    end
  end
end
