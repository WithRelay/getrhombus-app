# - you need a query for message volume for the last 7 days, last 90 days
# - you need a query for total conversations to date
# - you need a query for transaction this week...which will also be graphed by amount and data

module DashboardData

	def dashboard_messages_data
		{
			msg_7_days: { chart_data: message_volume(7) , msg_count: message_count(7) },
			msg_30_days: { chart_data: message_volume(30), msg_count: message_count(30) },
			msg_90_days: { chart_data: message_volume(90), msg_count: message_count(90) },
			total_convs: total_conversations
		}
	end

	def dashboard_customers_and_transactions
		customers = current_user.merchant_customers
    new_customers = customers.select{ |c| c.created_at >= 1.week.ago.utc }

    # Exclude refunded transactions, include subscriptions since these queries are read only
    # Otherwise you will need to exclude subscriptions which aren't easily refundable
    # and include only captured transactions and account reload txns are included by default..right
    all_txns = all_transactions
    txns_today = all_txns.where('transactions.created_at >= ?', Time.current.beginning_of_day)

    {
      all_customers_count: customers.length,
      new_customers_count: new_customers.length,
  		total_transactions: all_txns.sum(:amount),
      transactions_today: txns_today.present? ? txns_today.sum(:amount) : 0,
      transactions_today_count: txns_today.length
    }
	end

	def dashboard_transactions
		all_txns = all_transactions
    chart_data, recent_transactions = {}, {}

		# weekly_transactions = all_txns.where('transactions.created_at >=?', 7.days.ago.utc)
		# if merchant(current_user) has no bank account then the transactions data for the UI set to empty hash		
		if has_bank_account?
			chart_data = all_txns.where('transactions.created_at >=?', 7.days.ago.utc).group('date(transactions.created_at)').sum(:amount)
			recent_transactions = Transaction.includes(:user).exclude_refunded_transactions().only_captured_transactions()
																		    .where(team_id: merchant_id).order(created_at: :desc).last(6)			
		end

		{
			recent_trans: recent_transactions,
			this_week_tranc: all_txns.where('transactions.created_at >=?', 7.days.ago.utc).sum(:amount),
			tranc_chart_data: chart_data
		}
	end

  # Exclude refunded transactions, include subscriptions since these queries are read only
  # Otherwise you will need to exclude subscriptions which aren't easily refundable
  # and include only captured transactions and account reload txns are included by default..right
	# def chart_and_transactions
  # 	#data for chart, includes both fb_msg and sms
  #   {
  #     last6_transactions: Transaction.includes(:user).exclude_refunded_transactions().only_captured_transactions()
  #                                   .where(team_id: merchant_id).order(created_at: :desc).last(6),
  #     msg_data_for_chart: message_volume(30)
	#   }
	# end

	def dashboard_analytics_section
    data = conversations_handling_time

		avg_handle_time = data[:average_handle_time] != "0" ? data[:average_handle_time] + ' mins' : '-'
    open_convs_yesterday = get_open_convs_yesterday

		{
		  conversations_per_hour: data[:conversations_per_hour],
      #message_count method returns hash of message_per_day , fb_percent and sms_percent
      messages: message_count('today'),
      avg_handle_time: avg_handle_time,
		  open_convs_yesterday: open_convs_yesterday == 0 ? '-' : open_convs_yesterday
		}
	end

	#These methods below are used to collect data for merchant dashboard
  def message_volume(days)
    grouped_txt_data = Message.where("user_id= ? OR user_id_to= ?", merchant_id, merchant_id)
                        .where("created_at >= ?", days.days.ago.utc).group("date(created_at)").count
		grouped_fb_data = FbMessage.where("user_id= ? OR user_id_to= ?", merchant_id, merchant_id)
                        .where("created_at >= ?", days.days.ago.utc).group("date(created_at)").count

    #prepare data for chart
    #this will merge count of sms and fb_msg and add the coutes on the same day
    grouped_txt_data.merge(grouped_fb_data){|k, mv, fv| mv + fv}
  end

  def message_count(time)
		if time.class == String && time == 'today'
      create_at_date = Time.current.beginning_of_day
		elsif time.class == Fixnum
		  create_at_date = time.days.ago.utc
		end

    txt_msg = Message.where("(user_id= ? OR user_id_to= ?) and created_at >= ?", merchant_id, merchant_id, create_at_date)
    fb_msg = FbMessage.where("(user_id= ? OR user_id_to= ?) and created_at >= ?", merchant_id, merchant_id, create_at_date)

		msgs_count = txt_msg.length + fb_msg.length
    fb_msg_percent = fb_msg.present? ? 100 * fb_msg.length/msgs_count : 0
    txt_msg_percent = txt_msg.present? ? 100 * txt_msg.length/msgs_count : 0

    { total: msgs_count, fb_msg_percent: fb_msg_percent.round, txt_msg_percent: txt_msg_percent.round }
  end

  def conversations_handling_time
    data = ConversationResolution.total_minutes_to_resolve_conversations(merchant_id)
    if data.count == 0 || data.minutes_diff_total.blank? || data.minutes_diff_total == 0
      x, y = 0, 0
    else
      x = (data.minutes_diff_total/data.length.to_f).round(2)
      y = (data.length.to_f/(data.minutes_diff_total/60)).round(2)
    end

    { average_handle_time: "%g" % x, conversations_per_hour: "%g" % y }
  end

  def get_open_convs_yesterday
    ConversationResolution.where(merchant_id: merchant_id)
                          .where(created_at: (Time.current.beginning_of_day - 1.days)..(Time.current.beginning_of_day))
                          .count
  end

	def all_transactions
		Transaction.exclude_refunded_transactions().only_captured_transactions().where(team_id: merchant_id)
	end

	def total_conversations
    ConversationResolution.where(merchant_id: merchant_id).count
	end

 private

 	def merchant_id
 		current_user.id
 	end

	def has_bank_account?
		account = current_user.get_stripe_cred
		account[:type] != nil
	end

end
