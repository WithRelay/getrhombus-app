class WeeklyActivitySummaryJob

  include DashboardData
  include UserProfile

  @queue = :weekly_activity_summary

  def self.perform
    merchants = User.where(user_level: 1)
    merchants.each do |merchant|
      mail_data = mail_data_to_merchant(merchant)
      # sendmail(last_week_customers)
    end
  end

#  private
  def mail_data_to_merchant(merchant)
    Time.zone = merchant.time_zone
    last_week_customers = merchant.customers.where('merchant_customers.created_at >= ?', 7.days.ago.utc)
    #have to use UserProfile for fullname/ profile etc.
    { merchant_name: merchant.first_name, merchant_email: merchant.email, customers_list: last_week_customers }
  end

end
