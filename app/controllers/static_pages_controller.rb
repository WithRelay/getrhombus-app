class StaticPagesController < ApplicationController


	def home
	end

	def about
	end

	def terms
	end

	def privacy
	end

	def howitworks
	end

	def faqs
	end

	def storeowners
	end

	def to_404
		render :file => "#{Rails.root}/public/404.html", :status => 404, :layout => false
	end
end
