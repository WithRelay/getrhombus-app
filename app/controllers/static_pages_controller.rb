class StaticPagesController < ApplicationController

  [:home, :about, :privacy, :pricing, :faqs, :terms, :to_404, :request_demo, :features].each do |method_name|
    send :define_method, method_name do
      # do nothing
    end
  end

  [:text_messaging_for_schools_and_universities, :text_messaging_for_donations_and_nonprofits, :text_messaging_for_on_demand_services, :text_messaging_for_sales_and_marketing, :text_messaging_for_staffing_agencies].each do |method_name|
    send :define_method, method_name do
      # do nothing
    end
  end

  [:relay_docs, :platform_integrations, :text_messaging_for_customer_support].each do |method_name|
    send :define_method, method_name do
      # do nothing
    end
  end

end
