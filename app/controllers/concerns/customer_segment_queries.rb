module CustomerSegmentQueries

  OPERATORS = { 'more_than' => '>', 'less_than' => '<', 'exactly' => '=' }

  LAST_MESSAGE = %w(last_msg_received last_msg_sent)

  PURCHASED_CUSTOMER = %w(last_purchase new_customers)

  @filter_params = {}

  def customer_segment_query
    @filter_params = segment_params
    unless segment_type_mapper.nil? && segment_filter_mapper.nil?
      segment_filter_mapper + self.send(segment_type_mapper)
    end
  end

  protected

  def purchase_made_less_more_exactly
    "AND (CAST(t.created_at as DATE) #{map_amount_filter_to_operator} \
    CAST(DATE_SUB(NOW(), INTERVAL #{@filter_params[:segment_num_days]} DAY) as DATE))"
  end

  def message_recieved_less_more_exactly
    inner_join_transaction_user + "INNER JOIN messages as m on m.user_id = u.id WHERE \
    CAST(m.created_at as DATE) #{map_customer_filter_to_operator} \
    CAST(DATE_SUB(NOW(), INTERVAL #{@filter_params[:segment_num_days]} DAY) as DATE) AND "
  end

  def message_send_less_more_exactly
    inner_join_transaction_user + "INNER JOIN messages as m on m.user_id_to = u.id WHERE \
    CAST(m.created_at as DATE) #{map_customer_filter_to_operator} \
    CAST(DATE_SUB(NOW(), INTERVAL #{@filter_params[:segment_num_days]} DAY) as DATE) AND "
  end

  def created_less_than_more_than
    "AND m_c.created_at #{map_customer_filter_to_operator} DATE_SUB(NOW(), INTERVAL \
    #{@filter_params[:segment_num_days]} DAY)"
  end

  def created_exactly
    "AND CAST(m_c.created_at as DATE) = CAST(DATE_SUB(NOW(), INTERVAL \
    #{@filter_params[:segment_num_days]} DAY) as DATE)"
  end

  def spend_more_less_exactly
    inner_join_transaction_user + "where t.amount #{map_amount_filter_to_operator} \
    #{@filter_params[:amt_1]} AND t.team_id = #{team.id} "
  end

  def inner_join_transaction_user
    "SELECT * FROM users as u INNER JOIN transactions as t on u.id = t.user_id \
    INNER JOIN merchant_customers as m_c on (m_c.merchant_id = #{team.id} AND \
    m_c.customer_id = u.id)"
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

  def team
    current_user
  end

  def segment_filter_mapper
    return message_send_less_more_exactly if segment_params[:segment_type] == LAST_MESSAGE[0]
    return message_recieved_less_more_exactly if segment_params[:segment_type] == LAST_MESSAGE[1]
    return spend_more_less_exactly if PURCHASED_CUSTOMER.include?(segment_params[:segment_type])
  end

  def segment_type_mapper
    return :transaction_exactly_less_than if LAST_MESSAGE.include?(segment_params[:segment_type])
    return :purchase_made_less_more_exactly if segment_params[:segment_type] == PURCHASED_CUSTOMER[0]
    segment_filter_params = { 'new_customers_exactly' => :created_exactly,
                              'new_customers_less_than' => :created_less_than_more_than,
                              'new_customers_more_than' => :created_less_than_more_than }
    segment_filter_params["#{@filter_params[:segment_type]}_#{@filter_params[:segment_filter]}"]
  end
end
