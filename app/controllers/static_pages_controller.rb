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

  def request_demo; end

  def features; end

  def use_case_education; end

  def use_case_non_profit; end

  def use_case_demand_service; end

  def use_case_sales_marketing; end

  def use_case_staffing_employment; end

  def refer_a_business; end

  def relay_docs; end

	def creating_campaigns_in_relay
		@url = action_name.split('_').join("-")
	end

  def platform_integration; end

  def request_demo; end

  def features; end

  def use_case_education; end

  def use_case_non_profit; end

  def use_case_demand_service; end

  def use_case_sales_marketing; end

  def use_case_staffing_employment; end

  def use_case_customer_support; end

  def refer_a_business; end

  def relay_docs; end
end
