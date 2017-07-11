class StaticPagesController < ApplicationController

  [:home, :about, :privacy, :customers, :pricing, :faqs, :terms, :to_404, :request_demo, :features].each do |method_name|
    send :define_method, method_name do
      # do nothing
    end
  end

  [:use_case_education, :use_case_non_profit, :use_case_demand_service, :use_case_sales_marketing, :use_case_staffing_employment].each do |method_name|
    send :define_method, method_name do
      # do nothing
    end
  end

  [:refer_a_business, :relay_docs, :platform_integrations, :use_case_customer_support, :create_a_relay_account].each do |method_name|
    send :define_method, method_name do
      # do nothing
    end
  end

  def offline_check
    head :no_content
  end
end
