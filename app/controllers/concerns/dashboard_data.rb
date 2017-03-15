module DashboardData


	#These methods below are used to collect data for merchant dashboard
  def all_messages_count_in_30_days
    txt_messages = sent_and_received_messages('Message')
                    .where("created_at >=?", 30.days.ago.utc)
                    .group("DAY(created_at)").count

    fb_messages = sent_and_received_messages('FbMessage')
                    .where("created_at >=?", 30.days.ago.utc)
                    .group("DAY(created_at)").count

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
    @open_convs_yesterday = open_convs_yesterday 

    fb_msg_percent = fb_msg_today.present? ? 100 * fb_msg_today.count/today_msgs_count : 0
    txt_msg_percent = txt_msg_today.present? ? 100 * txt_msg_today.count/today_msgs_count : 0

    {msg_today: today_msgs_count, fb_msg_percent: fb_msg_percent.round(2), txt_msg_percent: txt_msg_percent.round(2)} 
  end

  def sent_and_received_messages(class_name)
    class_name.constantize.where("user_id= ? OR user_id_to= ?", current_user.id, current_user.id)
  end

  def avg_handle_time
    avg = Conversation.where(merchant_id: current_user.id).where.not(resolution: nil)
                      .average("DATEDIFF(updated_at,created_at)")            

    avg.present? ? avg/1.minutes : avg
  end

  def open_convs_yesterday
    yesterday_convs = Conversation.where(
                                  {merchant_id: current_user.id,
                                   resolution: nil,
                                   created_at: (Time.current.beginning_of_day - 1.days)..(Time.current.beginning_of_day)
                                  })
    yesterday_convs.count
  end

end