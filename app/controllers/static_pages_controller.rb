class StaticPagesController < ApplicationController


	def home
      #Notification.welcome_email("<redacted_email>", 1, "Taiwo Oyeniyi").deliver    
      #Notification.welcome_email("<redacted_email>", 0).deliver    
	end

	def aboutus
	end

	def privacy
	end
	
	def sellwithrhombus
	end

	def takedonations
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
