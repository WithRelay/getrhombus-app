class WeeklyActivitySummaryJob

  include DashboardData
  extend UserProfile

  @queue = :weekly_activity_summary

  class << self
    def perform
      merchants = User.where(user_level: 1)
      merchants.each do |merchant|
        mail_data = mail_data_to_merchant(merchant)
        EmailingService.send_weekly_mail(merchant, mail_data)
      end
    end

    #  private
    def mail_data_to_merchant(merchant = User.first)
      Time.zone = merchant.time_zone
      customers_array = []
      last_week_customers = merchant.customers.where('merchant_customers.created_at >= ?', 7.days.ago.utc)
      last_week_customers.each do |c|
        # have to use UserProfile for fullname/profile pic etc.
        customers_array  << {
                               full_name: get_conversation_display_name(c.id, 'user'),
                               profile_pic: check_profile_picture(c),
                               customer_email: c.email
                            }
      end

      { merchant_name: merchant.first_name,
        merchant_email: merchant.email,
        customers_list: customers_array,
        from_data: 7.days.ago.strftime("%A, %B %d"),
        till_data: Time.current.strftime("%A, %B %d")
      }
    end

    def weekly_transactions
        transactions = Transaction.exclude_refunded_transactions().only_captured_transactions()
                                  .where('team_id =? AND created_at >=?', current_user.id, 7.days.ago.utc)
    end

    def message_datas
      message_count('weekly')
    end

  end
end
