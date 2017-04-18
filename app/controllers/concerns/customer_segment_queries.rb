module CustomerSegmentQueries

  OPERATORS = {'more_than' => '>', 'less_than' => '<'}

  @filter_params = {}

  def created_spend_less_more_than
    spend_more_than_less_than + created_less_than_more_than
  end

  def created_spend_exactly
    spend_exactly + created_exactly
  end

  def message_send_spend
    inner_join_transaction_user + message_send_less_more_exactly + transaction_exactly_less_than
  end

  def message_recieved_spend
    inner_join_transaction_user + message_recieved_less_more_exactly + transaction_exactly_less_than
  end

  def purchase_made_with_spend
    spend_more_than_less_than + purchase_made_less_more_exactly
  end

  private

  def purchase_made_less_more_exactly
    "AND (CAST(t.created_at as DATE) #{map_amount_filter_to_operator} CAST(DATE_SUB(NOW(), \
     INTERVAL #{@filter_params[:segment_num_days]} DAY) as DATE)"
  end

  def message_recieved_less_more_exactly
    "INNER JOIN messages as m on m.user_id = u.id WHERE CAST(m.created_at as DATE) \
     #{map_customer_filter_to_operator} CAST(DATE_SUB(NOW(), INTERVAL
     #{@filter_params[:segment_num_days]} DAY) as DATE) AND "
  end

  def message_send_less_more_exactly
    "INNER JOIN messages as m on m.user_id_to = u.id WHERE CAST(m.created_at as DATE) \
     #{map_customer_filter_to_operator} CAST(DATE_SUB(NOW(), INTERVAL \
     #{@filter_params[:segment_num_days]} DAY) as DATE) AND "
  end

  def created_less_than_more_than
    "AND u.created_at #{map_customer_filter_to_operator} DATE_SUB(NOW(), INTERVAL \
    #{@filter_params[:segment_num_days]} DAY)"
  end

  def created_exactly
    "AND CAST(u.created_at as DATE) = CAST(DATE_SUB(NOW(), INTERVAL \
    #{@filter_params[:segment_num_days]} DAY) as DATE)"
  end

  def spend_exactly
    "SELECT * FROM users as u INNER JOIN transactions as t on u.id = t.user_id where t.amount = \
    #{@filter_params[:amt_1]} "
  end

  def spend_more_than_less_than
    "SELECT * FROM users as u INNER JOIN transactions as t on u.id = t.user_id where t.amount \
    #{map_amount_filter_to_operator} #{@filter_params[:amt_1]} "
  end

  def inner_join_transaction_user
    "SELECT * FROM users as u INNER JOIN transactions as t on u.id = t.user_id "
  end

  def transaction_exactly_less_than
    "t.amount \ #{map_amount_filter_to_operator} #{@filter_params[:amt_1]} "
  end

  def self.segment_filter_params(params)
    @filter_params = params
  end

  def map_amount_filter_to_operator
    OPERATORS[@filter_params[:amt_filter]]
  end

  def map_customer_filter_to_operator
    OPERATORS[@filter_params[:segment_filter]]
  end
end
