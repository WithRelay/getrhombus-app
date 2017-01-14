  class FacebookEvent
    
  class << self

    def process_event(params)
      @params = params
      if params['hub.mode'].present? #for verify webhook
        verify_webhook
      else #after verification for messenger event
        @required_params = params['entry'].last
        event = @required_params['messaging'].last
        read_event = event['read']
        message_event = event['message']
        # creates new conversation if not exists
        create_conversation

        if message_event.present?
          receive_message(event)
        elsif read_event.present?
          set_message_unread(event)
        end
      end
    end

    def verify_webhook
      # verify_token: <facebook_webhook_verify_token> #use in verifying webhooks. Generated randomly by us

      #access token below is the page access token unique to an app(Rhombus) an admin(Taiwo) and a FB page(shelflet)
      #It is gotten as part the response to calling the /me/accounts?access_token (see below) using the access token gotten during
      #fb authentication
      # subscription request: curl -ik -X POST "https://graph.facebook.com/v2.6/me/subscribed_apps?access_token="


      #access token below is the token given as part
      #of credentials during after successful authentication if requesting permissions for  pages_show_list or manage_pages
      # to get page access tokens for all the user's pages : https://graph.facebook.com/v2.6/me/accounts?access_token= 

      if @params['hub.mode'] == 'subscribe' && @params['hub.verify_token'] == "<facebook_webhook_verify_token>"
        return @params['hub.challenge']
      end     
      
      {}
    end

    def create_conversation
      merchant = current_page.user
      @merchant_id = merchant.id
      sender = @required_params['messaging'][0]['sender']
      recipient = @required_params['messaging'][0]['recipient']
      sender_id = sender['id']
      recipient_id = recipient['id']
      uid = (current_page.page_id == sender_id)? recipient_id : sender_id
      @conversation = Conversation.where(uid: uid).first_or_initialize
      update_conversation
    end

    def update_conversation
      @conversation.update(
        merchant_id: @merchant_id,
        uid_type: 'fb_page',
        message_resolution_id: 0      #message_resolution_id is bydefault 0
      )
    end

    def receive_message(params)
      begin
        message = params['message']
        @attachments = message['attachments']
        seq = message['seq']
        text = message['text']
        text = '' if text.nil?
        timestamp = set_timestamp(params['timestamp'])
        message_id =  message['mid']
        message_from = params['sender']['id']
        message_to = params['recipient']['id']
        fb_page_id = current_page.id
        new_user_id = (current_page.page_id == message_to)? message_from : message_to
        add_page_user(current_page, new_user_id)

        @fb_message = @conversation.fb_messages.create(text: text, seq: seq,
          time_stamp: timestamp, unread: false, message_id: message_id,
          from: message_from, to: message_to, fb_page_id: fb_page_id,
          user_id: get_user_id, user_id_to: @conversation.merchant_id)
        
        save_attachments if @attachments.present?
      rescue StandardError => err
        nil
      end
    end

    # set datetime in utc
    def set_timestamp(timestamp)
      sec = (timestamp.to_f / 1000).to_s
      DateTime.strptime(sec,'%s')
    end
        
    # Add new user from massenger to FbCred table
    def add_page_user(page, new_user_id)
      @fb_cred = FbCred.find_by(page_specific_id: new_user_id) || FbCred.add_fb_user_from_messenger(page, new_user_id)
    end

    # it gives user id from page specific id of user
    def get_user_id
      @fb_cred.user_id if @fb_cred
    end

    def save_attachments
      invalid_file = valid_file = false
      @attachments.each do |a|
        url = a['payload']['url']
        file_extension = File.extname(URI.parse(url).path).downcase
        if %w{.jpg .png .jpeg .gif .bmp}.include?(file_extension)
          image = @fb_message.images.new
          image.avatar_from_remote_url(url)
          valid_file = true
        else
          invalid_file = true
        end
      end

      # if invalid file attachment is send then it notify with error message
      notify_invalid_attachment if invalid_file

      # save message with valid attachments
      # message destroy if all attachments are not valid
      (valid_file) ? @fb_message.save! : @fb_message.destroy
    end

    def set_message_unread(params)
      messages = FbMessage.where(to: params['sender']['id'], unread: false)
      messages.update_all(unread: true)
    end

    def notify_invalid_attachment
      page = @fb_message.fb_page
      if page.page_id != @fb_message.from
        user = FbCred.find_by_page_specific_id @fb_message.from
        to = @fb_message.from
      else
        user = page.fb_cred
        to = @fb_message.to
      end
      user_name = user.name.split.first
      page_access_token = page.page_access_token
      text = "Sorry #{user_name}, currently we only support image file attachments"
      FacebookMessengerService.send_text_message(page_access_token, to, text)
    end

    def current_page
      FbPage.find_by_page_id @required_params['id']
    end

  end

end
