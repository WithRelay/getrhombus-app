module DashboardNotification
  def set_notifications
    unless current_user.nil?
      beginning_of_day = Time.current.beginning_of_day
      @todays_last5_txns = Transaction.get_merchant_todays_last5_txns(current_user.id, beginning_of_day)
      @todays_txns_count = Transaction.get_merchant_todays_txn_count(current_user.id, beginning_of_day)
      @todays_last_msgs_from_last5_convs = Conversation.get_last_customer_msg_from_last5_convs_today(current_user.id, beginning_of_day)
      @todays_unread_convs_count = Conversation.get_merchant_todays_unread_count(current_user.id, beginning_of_day)
    end
  end
end
