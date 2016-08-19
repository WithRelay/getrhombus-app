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

	    if params['hub.mode'] == 'subscribe' && params['hub.verify_token'] == "<facebook_webhook_verify_token>"
	      puts "Validating webhook"
	      render json: params['hub.challenge']
	    else
	      render json: {}     
		end
		#<facebook_webhook_verify_token>
	end

	def customer_info_xls_template
    render :template => "static_pages/to_404.html" and return if !current_user && current_user.user_level != 1
    response = current_user.customer_info_xls_template
    if response
      respond_to do |format|
        format.xls { send_data response, :filename => "customer_info.xls", :type =>  "", status: 200 } 
      end
    else
      # use 500 page after it is built
      render :template => "static_pages/to_404.html"
    end
  end

end
