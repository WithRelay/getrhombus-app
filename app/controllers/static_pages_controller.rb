class StaticPagesController < ApplicationController


	def home
	end

	def about
	end

	def privacy
	end
	
	def customers
	end

	def pricing
	end

	def faqs
	end

	def terms
	end

	def to_404
	end

	def fb_webhook
		#curl -Ls https://burrow.io/zkjAouRf-lhp7HvZt | bash -s
		#https://uzhoadtv.burrow.io -> http://localhost:3000
		# curl -ik -X POST "https://graph.facebook.com/v2.6/me/subscribed_apps?access_token=" #use this to subscribe
		puts "Any thing"

	    if params['hub.mode'] == 'subscribe' && params['hub.verify_token'] == "<facebook_webhook_verify_token>"
	      puts "Validating webhook"
	      render json: params['hub.challenge']
	    else
	      render json: {}     
		end
		#<facebook_webhook_verify_token>
	end

	def receive_message
		puts params[:entry][0][:messaging][0][:message][:text]
		# send_message
		render :json => {:object => "received"}, :status => 200
	end

	def send_message
		send_api_client = MessageQuickly::Api::Client.new do |client|
		  client.page_access_token = '<redacted_facebook_access_token>'
		  client.page_id = '<redacted_phone_number>'
		end

		MessageQuickly::Api::UserProfile.new(send_api_client).find('508378145')

		recipient = MessageQuickly::Messaging::Recipient.new(id: '<redacted_phone_number>')

		delivery = MessageQuickly::Api::Messages.create(recipient) do |message|
  			message.text = 'Hello'
		end
	end

end