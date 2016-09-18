class FacebookEvent
    
  class << self

  	def process_event(params)
  		@params = params
  		
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

		def receive_message
			message = params[:entry][0][:messaging][0][:message][:text]
			# send_message
			render :json => {:object => "received"}, :status => 200
		end
    
  end
end
