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
		#curl -Ls https://burrow.io/qzDWcjhe-lhp7HvZt | bash -s
		#https://sqfosv4e.burrow.io -> http://localhost:3000
		puts params
		puts "Any thing"

	    if params['hub.mode'] == 'subscribe' && params['hub.verify_token'] == "<facebook_webhook_verify_token>"
	      puts "Validating webhook"
	      render json: params['hub.challenge']
	    else
	      render json: {}     
		end
		#<facebook_webhook_verify_token>
	end

end