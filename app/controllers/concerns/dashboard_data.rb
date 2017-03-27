# - you need a query for message volume for the last 7 days, last 90 days
# - you need a query for total conversations to date
# - you need a query for transaction this week...which will also be graphed by amount and data

module DashboardData

	def messages
		messages_7days = message_volume(7)
	end

	def customers_and_trasactions
		customers = current_user.merchant_customers
    new_customers = customers.select{ |c| c.created_at >= 1.week.ago.utc }

    # Exclude refunded transactions, include subscriptions since these queries are read only
    # Otherwise you will need to exclude subscriptions which aren't easily refundable
    # and include only captured transactions and account reload txns are included by default..right
    transactions = all_trasactions
    transactions_today = transactions.where('transactions.created_at >=?', Time.current.beginning_of_day)

    {
      all_customers_count: customers.count,
      new_customers_count: new_customers.count,
  		total_transactions: transactions.sum(:amount),
      transactions_today: transactions_today.present? ? transactions_today.sum(:amount) : 0,
      transactions_today_count: transactions_today.count
    }
	end

	def total_conversations
		#Conversation.where(merchant_id: merchant_id).count
    ConversationResolution.where(merchant_id: merchant_id).count
	end

	def transactions
		transactions = all_trasactions
		#weekly transactions
		transactions_weekly = transactions.where 'transactions.created_at >=?', 7.days.ago.utc
		{
			recent_trancs: Transaction.includes(:user).exclude_refunded_transactions().only_captured_transactions()
                                    .where(team_id: merchant_id).order(created_at: :desc).last(6),
			this_week_tranc: transactions_weekly.sum(:amount)
		}
	end

  # Exclude refunded transactions, include subscriptions since these queries are read only
  # Otherwise you will need to exclude subscriptions which aren't easily refundable
  # and include only captured transactions and account reload txns are included by default..right
	def chart_and_transactions
  	#data for chart, includes both fb_msg and sms
    {
      last6_transactions: Transaction.includes(:user).exclude_refunded_transactions().only_captured_transactions()
                                    .where(team_id: merchant_id).order(created_at: :desc).last(6),
      msg_data_for_chart: message_volume(30)
	  }
	end

	def analytics_section
    data = conversations_handling_time
		{
		  conversations_per_hour: data[:conversations_per_hour],
      #message_count method returns hash of message_per_day , fb_percent and sms_percent
      messages: message_count('today'),
      avg_handle_time: data[:average_handle_time],
		  open_convs_yesterday: open_convs_yesterday
		}
	end

	#These methods below are used to collect data for merchant dashboard
  def message_volume(days)
    txt_messages = sent_and_received_messages('Message')
                    .where("created_at >=?", days.days.ago.utc)
                    .group("date(created_at)").count

    fb_messages = sent_and_received_messages('FbMessage')
                    .where("created_at >=?", days.days.ago.utc)
                    .group("date(created_at)").count

    #prepare data for chart
    #this will merge count of sms and fb_msg and add the coutes on the same day
    data = txt_messages.merge(fb_messages){|k, mv, fv| mv + fv}
  end

  def message_count(time)
    txt_msg_total, fb_msg_total = sent_and_received_messages('Message'),
                      sent_and_received_messages('FbMessage')
		if time == 'today'
	    txt_msg = txt_msg_total.select { |t| t.created_at >= Time.current.beginning_of_day }
	    fb_msg = fb_msg_total.select { |t| t.created_at >= Time.current.beginning_of_day }
		elsif time == 'weekly'
			txt_msg = txt_msg_total.select { |t| t.created_at >= 7.days.ago.utc }
	    fb_msg = fb_msg_total.select { |t| t.created_at >= 7.days.ago.utc }
		end

		msgs_count = txt_msg.count + fb_msg.count

    fb_msg_percent = fb_msg.present? ? 100 * fb_msg.count/msgs_count : 0
    txt_msg_percent = txt_msg.present? ? 100 * txt_msg.count/msgs_count : 0

    { msg_count: msgs_count, fb_msg_percent: fb_msg_percent.round, txt_msg_percent: txt_msg_percent.round }
  end

  def sent_and_received_messages(class_name)
    class_name.constantize.where("user_id= ? OR user_id_to= ?", merchant_id, merchant_id)
  end

  def conversations_handling_time
    data = ConversationResolution.total_minutes_to_resolve_conversations(merchant_id)
    if data.count == 0 || data.minutes_diff_total.blank? || data.minutes_diff_total == 0
      x, y = 0, 0
    else
      x = (data.minutes_diff_total/data.count.to_f).round(2)
      y = (data.count.to_f/(data.minutes_diff_total/60)).round(2)
    end

    { average_handle_time: "%g" % x, conversations_per_hour: "%g" % y }
  end

  def open_convs_yesterday
    yesterday_convs = ConversationResolution.where(merchant_id: merchant_id)
                            .where(created_at: (Time.current.beginning_of_day - 1.days)..(Time.current.beginning_of_day))
    yesterday_convs.count
  end

	def all_trasactions
		Transaction.exclude_refunded_transactions().only_captured_transactions().where(team_id: merchant_id)
	end

 private

 	def merchant_id
 		current_user.id
 	end

end
