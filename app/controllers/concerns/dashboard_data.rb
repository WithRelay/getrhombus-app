module DashboardData
	
	def overall_section
		customers = current_user.merchant_customers
    new_customers = customers.select{ |c| c.created_at >= 1.week.ago.utc }

    transactions = Transaction.where( team_id: merchant_id)
    transactions_today = transactions.select{|t| t.created_at >= Time.current.beginning_of_day}
   
  {
    all_customers_count: customers.count,
    new_customers_count: new_customers.count,
		total_transactions: transactions.sum(:amount),
    transactions_today: transactions_today.present? ? transactions_today.sum(:amount) : 0,
    transactions_today_count: transactions_today.count
  }

	end

	def chart_and_transactions
		# Transaction.process_captured_payment(@user, params) if current_user.user_level == 0 && params[:captured_amt].present?
  	#data for chart, includes both fb_msg and sms
   {
    last6_transactions: Transaction.includes(:user).where(team_id: merchant_id).order(created_at: :desc).last(6),
    msg_data_for_chart: all_messages_count_in_30_days
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
		 conversations_per_hour: Conversation.conversation_per_hour(current_user) || 0,

    #message_count method returns hash of message_per_day , fb_percent and sms_percent  
     messages: message_count,
     avg_handle_time: avg_handle_time.round(2),
		 open_convs_yesterday: open_convs_yesterday
		}

	end

	#These methods below are used to collect data for merchant dashboard
  def all_messages_count_in_30_days
    txt_messages = sent_and_received_messages('Message')
                    .where("created_at >=?", 30.days.ago.utc)
                    .group("monthname(created_at)").group("DAY(created_at)").count

    fb_messages = sent_and_received_messages('FbMessage')
                    .where("created_at >=?", 30.days.ago.utc)
                    .group("monthname(created_at)").group("DAY(created_at)").count

    #prepare data for chart 
    #this will merge count of sms and fb_msg and add the coutes on the same day              
    txt_messages.merge(fb_messages){|k, mv, fv| mv + fv}
  end

  def message_count
    txt_msg, fb_msg = sent_and_received_messages('Message'), 
                      sent_and_received_messages('FbMessage')

    txt_msg_today = txt_msg.select {|t| t.created_at >= Time.current.beginning_of_day}
    fb_msg_today   = fb_msg.select  {|t| t.created_at >= Time.current.beginning_of_day}
    today_msgs_count = txt_msg_today.count + fb_msg_today.count 

    fb_msg_percent = fb_msg_today.present? ? 100 * fb_msg_today.count/today_msgs_count : 0
    txt_msg_percent = txt_msg_today.present? ? 100 * txt_msg_today.count/today_msgs_count : 0

    {msg_today: today_msgs_count, fb_msg_percent: fb_msg_percent.round(2), txt_msg_percent: txt_msg_percent.round(2)} 
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
                                  {merchant_id: merchant_id,
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