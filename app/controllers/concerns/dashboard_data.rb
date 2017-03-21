# - you need a query for message volume for the last 7 days, last 90 days
# - you need a query for total conversations to date
# - you need a query for transaction this week...which will also be graphed by amount and data

module DashboardData

	def overall_section
		customers = current_user.merchant_customers
    new_customers = customers.select{ |c| c.created_at >= 1.week.ago.utc }

    # Exclude refunded transactions, include subscriptions since these queries are read only
    # Otherwise you will need to exclude subscriptions which aren't easily refundable
    # and include only captured transactions and account reload txns are included by default..right
    transactions = Transaction.exclude_refunded_transactions().only_captured_transactions().where(team_id: current_user.id)
    transactions_today = transactions.select{ |t| t.created_at >= Time.current.beginning_of_day }

		#weekly transactions
		transactions_weekly = transactions.select{|t| t.created_at >= 7.days.ago.utc }

    {
      all_customers_count: customers.count,
      new_customers_count: new_customers.count,
  		total_transactions: transactions.sum(:amount),
      transactions_today: transactions_today.present? ? transactions_today.sum(:amount) : 0,
      transactions_today_count: transactions_today.count
    }
	end

	def total_conversations
		Conversation.where(merchant_id: current_user.id).count
	end

  # Exclude refunded transactions, include subscriptions since these queries are read only
  # Otherwise you will need to exclude subscriptions which aren't easily refundable
  # and include only captured transactions and account reload txns are included by default..right
	def chart_and_transactions
  	#data for chart, includes both fb_msg and sms
   {
    last6_transactions: Transaction.includes(:user).exclude_refunded_transactions().only_captured_transactions()
                                    .where(team_id: current_user.id)
                                    .order(created_at: :desc).last(6),
    msg_data_for_chart: message_volume(30)
	  }
	end

	def unread_preview_section
		{
			message_count: Conversation.get_merchant_total_unread_msgs_count(current_user),
	    messages_last_5: ConversationRef.get_last_msgs_from_all_merchant_convs(current_user)
	  }
	end

	def msg_performance_section
		{
		 conversations_per_hour: Conversation.conversation_per_hour(current_user),
     #message_count method returns hash of message_per_day , fb_percent and sms_percent
     messages: message_count,
     avg_handle_time: avg_handle_time.round,
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

  def message_count
    txt_msg, fb_msg = sent_and_received_messages('Message'),
                      sent_and_received_messages('FbMessage')

    txt_msg_today = txt_msg.select { |t| t.created_at >= Time.current.beginning_of_day }
    fb_msg_today = fb_msg.select { |t| t.created_at >= Time.current.beginning_of_day }
    today_msgs_count = txt_msg_today.count + fb_msg_today.count

    fb_msg_percent = fb_msg_today.present? ? 100 * fb_msg_today.count/today_msgs_count : 0
    txt_msg_percent = txt_msg_today.present? ? 100 * txt_msg_today.count/today_msgs_count : 0

    { msg_today: today_msgs_count, fb_msg_percent: fb_msg_percent.round, txt_msg_percent: txt_msg_percent.round }
  end

  def sent_and_received_messages(class_name)
    class_name.constantize.where("user_id= ? OR user_id_to= ?", merchant_id, merchant_id)
  end

  def avg_handle_time
    avg = Conversation.where(merchant_id: merchant_id).where.not(resolution: nil)
                      .average("DATEDIFF(updated_at,created_at)")

    avg.present? ? avg/1.minutes : 0 #returns 0 if there is no data for average
  end

  def open_convs_yesterday
    yesterday_convs = Conversation.where(
                                  { merchant_id: merchant_id,
                                    resolution: nil,
                                    created_at: (Time.current.beginning_of_day - 1.days)..(Time.current.beginning_of_day)
                                  })
    yesterday_convs.count
  end

 private

 	def merchant_id
 		current_user.id
 	end

end
