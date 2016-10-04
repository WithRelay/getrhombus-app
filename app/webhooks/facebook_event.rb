  class FacebookEvent
    
  class << self

  	def process_event(params)
      required_params = params['entry'].last
      event = required_params['messaging'].last
      read_event = event['read']
      message_event = event['message']
      # delivery_event = event['delivery']
      create_conversation(required_params)

  		if params['hub.mode'].present?
  			verify_webhook
      elsif read_event.present?
        set_message_unread(event)
      elsif message_event.present?
        receive_message(required_params['id'], event)
      else 
  		end

  	end

    def create_conversation(params)
      current_page = FbPage.find_by_page_id params['id']
      current_user = current_page.fb_cred.user
      merchant_id = current_page.id
      sender = params['messaging'][0]['sender']
      recipient = params['messaging'][0]['recipient']
      sender_id = sender['id']
      recipient_id = recipient['id'] 
      uid = (current_page.page_id == sender_id)? recipient_id : sender_id
      unless (Conversation.find_by_uid uid).present?
        Conversation.create(merchant_id: merchant_id, uid: uid, resolution: false)
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

		def receive_message(page_id, params)
      begin
        message = params['message']
        attachments = message['attachments']
        seq = message['seq']
        text = message['text']
        text = '' if text.nil?
        timestamp = set_timestamp(params['timestamp'])
        message_id =  message['mid']
        message_from = params['sender']['id']
        message_to = params['recipient']['id']
        current_page = FbPage.find_by_page_id page_id
        fb_page_id = current_page.id
        new_user_id = (page_id == message_to)? message_from : message_to
        add_page_user(fb_page_id, new_user_id)        

        conversation = Conversation.find_by_uid new_user_id
        fb_message = conversation.fb_messages.create(text: text, seq: seq, time_stamp: timestamp, unread: false, 
          message_id: message_id, page_id: page_id, from: message_from, to: message_to, 
          fb_page_id: fb_page_id)
  			
        save_attachments(attachments, fb_message)
        fb_message.save!
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
    def add_page_user(page_id, new_user)
      unless (FbCred.find_by_page_specific_id new_user).present?
        FbCred.add_fb_user_from_massenger(page_id, new_user)
      end
    end

    def save_attachments(attachments, fb_message)
      if attachments.present?
        attachments.each do |a|
          url = a['payload']['url']
          image = fb_message.images.new
          image.avatar_from_remote_url(url)
        end
      end
    end

    def set_message_unread(params)
      messages = FbMessage.all.where(to: params['sender']['id'], unread: false)
      messages.update_all(unread: true)
    end

  end
end
