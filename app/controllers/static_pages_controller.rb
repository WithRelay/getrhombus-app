# renders all static pages as mention in its action
class StaticPagesController < ApplicationController

  def home; end

	def about; end

	def privacy; end

	def customers; end

	def pricing; end

	def faqs; end

	def terms; end

	def to_404; end

	def relay_docs
	end

	def creating_campaigns_in_relay
		@url = action_name.split('_').join("-")
	end

  def platform_integration; end

  def request_demo; end

  def features; end
end
