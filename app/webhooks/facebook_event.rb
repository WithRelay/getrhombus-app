  class FacebookEvent
    
  class << self

  	def process_event(params)
      message_params = params['entry'].last
      receive_message(message_params)
  		if params['hub.mode'].present?
  			verify_webhook
  		else
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

		def receive_message(params)
      begin
        messaging = params['messaging'].last
        message = messaging['message']
        attachments = message['attachments']
        seq = message['seq']
        text = message['text']
        text = '' if text.nil?
        timestamp = set_timestamp(messaging['timestamp'])
        message_id =  message['mid']
        message_from = messaging['sender']['id']
        message_to = messaging['recipient']['id']
        current_page = FbPage.find_by_page_id params['id']
        fb_page_id = current_page.id

        add_page_user(message_from)        

        fb_message = FbMessage.create(text: text, seq: seq, time_stamp: timestamp, unread: true, 
          message_id: message_id, page_id: message_to, from: message_from, to: message_to, fb_page_id: fb_page_id)
  			
        save_attachment(attachments, fb_message)
        fb_message.save!
      rescue StandardError => err
        nil
      end
		end 

    def set_timestamp(timestamp)
      sec = (timestamp.to_f / 1000).to_s
      DateTime.strptime(sec,'%s')
    end
        
    # Add new user from massenger to FbCred table
    def add_page_user(uid)
      unless (FbCred.find_by_page_specific_id uid).present?
        FbCred.add_fb_user_from_massenger(fb_page_id, message_from)
      end
    end

    def save_attachment(attachments, fb_message)
      if attachments.present?
        attachments.each do |a|
          url = a['payload']['url']
          image = fb_message.images.new
          image.avatar_from_remote_url(url)
        end
      end
    end

  end
end
