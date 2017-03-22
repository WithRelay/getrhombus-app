class WeeklyEmailJob < ApplicationJob
  include DashboardData
  include UserProfile

  def self.new_customers_this_week
    merchants = User.where(user_level: 1)
    merchants.each do |merchant|
      mail_data = mail_data_to_merchant(merchant)
      # sendmail(last_week_customers)
    end
  end

  private
  def mail_data_to_merchant(merchant)
    customers = merchant.customers
    last_week_customers = customers.select{|c| c.created_at >= 7.days.ago.utc }
    #have to use UserProfile for fullname/ profile etc.
    {merchant_name: merchant.first_name, merchant_email: merchant.email, customers_list: last_week_customers }
  end
end
