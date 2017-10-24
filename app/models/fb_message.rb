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
  # page = merchant page object, to = recipient_id
  def send_and_save_message(merchant, user, page, to, message, media_urls = [])
    begin
      # save message before sending
      self.update_attributes(user_id: merchant.id, user_id_to: user.try(:id), from: page.page_id, to: to, text: message, fb_page_id: page.id)

      response = FacebookMessengerService.send_text_message(page.page_access_token, to, message)
      if response.code == 200
        self.update_column(:message_id, JSON.parse(response)['message_id'])

        if media_urls.present?
          # now we only support image file attachment
          attachment_type = 'image'
          media_urls.each{ |url| FacebookMessengerService.send_attachment(page.page_access_token, to, attachment_type, url) }
        end
        return true
      else
        ExceptionNotifier.notify_exception(StandardError.new, data: { message: "From FbMessage.rb send_and_save_message, unable to send message", page: page, to: to, text: message, env: Rails.env, response: response })
      end
    rescue StandardError => err
    end

    ExceptionNotifier.notify_exception(err, data: { message: "From FbMessage.rb send_and_save_message, unable to send message", page: page, to: to, text: message, env: Rails.env, response: response })
    false
  end
end
