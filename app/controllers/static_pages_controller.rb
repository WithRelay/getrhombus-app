require 'httparty'
class StaticPagesController < ApplicationController


	def home
		# send_message
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
		#open tunnel: curl -Ls https://burrow.io/qzDWcjhe-lhp7HvZt | bash -s
		#tunnel url: https://sqfosv4e.burrow.io -> http://localhost:3000

		# verify_token: <facebook_webhook_verify_token> #use in verifying webhooks. Generated randomly by us

		#access token below is the page access token unique to an app(Rhombus) an admin(Taiwo) and a FB page(shelflet)
		#It is gotten as part the response to calling the /me/accounts?access_token (see below) using the access token gotten during
		#fb authentication
		# subscription request: curl -ik -X POST "https://graph.facebook.com/v2.6/me/subscribed_apps?access_token="


		#access token below is the token given as part
		#of credentials during after successful authentication if requesting permissions for  pages_show_list or manage_pages
		# to get page access tokens for all the user's pages : https://graph.facebook.com/v2.6/me/accounts?access_token= 

	    if params['hub.mode'] == 'subscribe' && params['hub.verify_token'] == "<facebook_webhook_verify_token>"
	      render json: params['hub.challenge']
	    else
	      render json: {}     
		end
	end

	def receive_message
		message = params[:entry][0][:messaging][0][:message][:text]
		# send_message
		render :json => {:object => "received"}, :status => 200
	end

	def send_message
		# using message quickly
		# send_api_client = MessageQuickly::Api::Client.new do |client|
		#   client.page_access_token = '<redacted_facebook_access_token>'
		#   client.page_id = '<redacted_phone_number>'
		# end

		# MessageQuickly::Api::UserProfile.new(send_api_client).find('508378145') #use Taiwo's FB id

		# recipient = MessageQuickly::Messaging::Recipient.new(id: '<redacted_phone_number>') #use recipients FB id

		# delivery = MessageQuickly::Api::Messages.create(recipient) do |message|
  # 			message.text = 'Hello'
		# end


		
		#Using HTTParty
		options = { body: {
		  "recipient" => {
		  	"id" => "<redacted_phone_number>"
		  },
		  "message" => {
		  	"text" => "hello, world!"
		  }
		}.to_json,
		headers: { 'Content-Type' => 'application/json' }}
		url = "https://graph.facebook.com/v2.6/me/messages?access_token=<redacted_facebook_access_token>"
		HTTParty.post(url, options)
	end

end