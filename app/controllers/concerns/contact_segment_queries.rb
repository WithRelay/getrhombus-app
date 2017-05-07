module ContactSegmentQueries

  @filter_params = {}

  OPERATORS = { 'more_than' => '>', 'less_than' => '<', 'exactly' => '=' }

  SEND_RECEIVED = { 'last_msg_received' => 'm.to', 'last_msg_sent' => 'm.from' }

  def contact_segment_query
    map_message.present? ? message_send_received : contacts_created
  end

  def contacts_created
    "select * from merchant_contacts as contacts where contacts.created_at \
    #{map_operators} DATE_SUB(NOW(), INTERVAL #{@filter_params[:segment_num_days]} DAY) \
    AND contacts.merchant_id = #{team_id}"
  end

  def message_send_received
    "select * from merchant_contacts as c inner join messages as m on #{map_message} = c.uid \
    where c.merchant_id = #{team_id} AND #{map_merchant_message} = #{team_id} AND \
    m.created_at #{map_operators} DATE_SUB(NOW(), INTERVAL #{@filter_params[:segment_num_days]} DAY)"
  end

  def team_id
    current_user.id
  end

  def map_operators
    OPERATORS[@filter_params[:segment_filter]]
  end

  def map_merchant_message
    map_message == 'm.to' ? 'm.from' : map_message
  end

  def map_message
    SEND_RECEIVED[@filter_params[:segment_type]]
  end
end
