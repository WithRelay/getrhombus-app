class StaticPagesController < ApplicationController


	def home
	end

	def aboutus
	end

	def privacy
	end
	
	def sellwithrhombus
	end

	def takedonations
	end

	def receipt
		#Notification.send_receipt().deliver #response, tax_rate, merchant.business_name
	end

	def faqs
	end

	def paywithrhombus
	end

	def legal
	end

	def to_404
		render :file => "#{Rails.root}/public/404.html", :status => 404, :layout => false
	end
end
