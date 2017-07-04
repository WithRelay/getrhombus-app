module SegmentQueries
  extend ActiveSupport::Concern
  
  # 1. New customers - last 7 days
  def new_customers_default_segment(data)
    "select * from merchant_customers where created_at >= '#{data["time"]}' and merchant_id = #{data["merchant_id"]} "
  end

  def new_customers_default_segment_data
    { base_query: "new_customers_default_segment", base_val: 7 }
  end
       
  # 2. Active customer - a transaction or message in the last 30 days. 
  # These actions update the merchant_customers table so we just query it directly
  def active_customers_default_segment(data)
    "select * from merchant_customers where updated_at >= '#{data["time"]}' and merchant_id = #{data["merchant_id"]} "
  end

  def active_customers_default_segment_data
    { base_query: "active_customers_default_segment", base_val: 30 }
  end

  # 3. Inactive customer - no transaction or message in the last 30 days. 
  # These actions update the merchant_customers table so we just query it directly
  def inactive_customers_default_segment(data)
    "select * from merchant_customers where updated_at <= '#{data["time"]}' and merchant_id = #{data["merchant_id"]} "
  end

  def inactive_customers_default_segment_data
    { base_query: "inactive_customers_default_segment", base_val: 30 }
  end

  # 1. New contacts - last 7 days
  def new_contacts_default_segment(data)
    "select * from merchant_contacts where created_at >= '#{data["time"]}' and merchant_id = #{data["merchant_id"]} and is_customer = false "
  end

  def new_contacts_default_segment_data
    { base_query: "new_contacts_default_segment", base_val: 7 }
  end

  # 2. Active contacts - a message in the last 30 days. 
  # These action updates the merchant_contacts table so we just query it directly
  def active_contacts_default_segment(data)
    "select * from merchant_contacts where updated_at >= '#{data["time"]}' and merchant_id = #{data["merchant_id"]} and is_customer = false "
  end

  def active_contacts_default_segment_data
    { base_query: "active_contacts_default_segment", base_val: 30 }
  end

  # 3. Inactive contacts - no message in the last 30 days. 
  # These action updates the merchant_contacts table so we just query it directly
  def inactive_contacts_default_segment(data)
    "select * from merchant_contacts where updated_at <= '#{data["time"]}' and merchant_id = #{data["merchant_id"]} and is_customer = false"
  end

  def inactive_contacts_default_segment_data
    { base_query: "inactive_contacts_default_segment", base_val: 30 }
  end

  # Creates a segment for a plan
  def plan_segment(data)
    "select mc.* from merchant_customers mc inner join subscriptions s on mc.id = s.merchant_customer_id where mc.merchant_id = #{data["merchant_id"]}
      and s.plan_id = #{data["plan_id"]}"
  end

  def plan_segment_data(plan_id)
    { base_query: "plan_segment", plan_id: plan_id }
  end

  def customer_last_message_received(data)
    customer_message_string(data, 2)
  end

  def customer_last_message_sent(data)
    customer_message_string(data, 1)
  end

  def contact_last_message_received(data)
    contact_message_string(data, 2)
  end

  def contact_last_message_sent(data)
    contact_message_string(data, 1)
  end

  def customer_created(data)    
    customer_or_contact_created(data, 'customer')
  end

  def contact_created(data)    
    customer_or_contact_created(data, 'contact')
  end

  def last_payment_made(data)
    str = " select distinct(mc.customer_id), mc.merchant_id, mc.id, mc.created_at, mc.updated_at from merchant_customers mc 
            inner join transactions t on t.user_id = mc.customer_id "

    if data["additional_val"].present?  # amount for now
      str += " #{get_amount_filter(data["additional_filter"], data["additional_val"])} and "
    else
      str += " where "
    end

    str += " mc.merchant_id = #{data["merchant_id"]} and 
             t.created_at #{get_base_filter(data["base_filter"])} '#{data["time"]}' and t.team_id = #{data["merchant_id"]} "
  end

  private

  def customer_message_string(data, source)
    str = "select id, customer_id, merchant_id, created_at, updated_at from
            (select uids.* from 
              (
                select mc.id as id, mc.customer_id, mc.merchant_id, cr.created_at as message_time, mc.created_at as created_at, mc.updated_at
                from merchant_customers mc 
                inner join conversations c on mc.customer_id = c.uid and c.uid_type = 'user' and mc.merchant_id = c.merchant_id
                inner join conversation_refs cr on c.id = cr.conversation_id    
                where mc.merchant_id = #{data["merchant_id"]} and mc.customer_id is not null
                and cr.source = #{source} and cr.created_at #{get_base_filter(data["base_filter"])} '#{data["time"]}' 
              ) uids "

    str += data["additional_val"].present? ? transactions_substring(data) : " order by uids.message_time "
    str += ') ids group by ids.customer_id '
  end

  def transactions_substring(data)
    return "" if data["additional_val"].blank?
    " inner join transactions t on uids.id = t.user_id and t.team_id = #{data["merchant_id"]}
      #{get_amount_filter(data["additional_filter"], data["additional_val"])} order by t.created_at "
  end

  def contact_message_string(data, source)
    "select * from
      (
        select mc.* from merchant_contacts mc 
        inner join conversations c on mc.uid = c.uid and mc.uid_type = c.uid_type and mc.merchant_id = c.merchant_id
        inner join conversation_refs cr on c.id = cr.conversation_id
        where mc.merchant_id = #{data["merchant_id"]} 
        and mc.is_customer = false and mc.uid_type is not null and mc.uid is not null
        and cr.source = #{source} and cr.created_at #{get_base_filter(data["base_filter"])} '#{data["time"]}' order by cr.created_at
      ) ids group by concat(uid,uid_type) "
  end

  def customer_or_contact_created(data, user_type)    
    if user_type == 'contact'
      str = " select * from merchant_contacts mc "
    else
      str = " select distinct(mc.customer_id), mc.id, mc.merchant_id, mc.created_at, mc.updated_at from merchant_customers mc "
    end

    # note contacts will never have amount for transactions
    if data["additional_val"].present?
      str += " inner join transactions t on mc.customer_id = t.user_id and t.team_id = #{data["merchant_id"]} 
                #{get_amount_filter(data["additional_filter"], data["additional_val"])} and "
    else
      str += " where " + (user_type == "contact" ? " mc.is_customer = false and " : "")
    end

    str += " mc.merchant_id = #{data["merchant_id"]} and mc.created_at #{get_base_filter(data["base_filter"])} '#{data["time"]}' "
  end

  def get_base_filter(filter_type)
    symbol = ''
    if filter_type == "more_than"
      symbol = "<"
    elsif filter_type == "exactly"
      symbol = "="
    elsif filter_type == "less_than"
      symbol = ">"
    end
    return symbol
  end

  # Returns a SQL statement for filtering the total amount spent by a customer
  # by amount range
  # @param filter_type The type of filter passed
  # @param amount_1 The first amount in the range
  # @param amount_2 The second amount in the range
  def get_amount_filter(filter_type, amount_1, amount_2 =0)
    sql_statement = ""
    spend = "WHERE t.amount"    
    if filter_type == "less_than"
      sql_statement = "#{spend} < #{amount_1}"
    #elsif filter_type == "between"
    #  sql_statement = "#{spend} >= #{amount_1} AND #{spend} < #{amount_2}"
    elsif filter_type == "exactly"
      sql_statement = "#{spend} = #{amount_1}"
    elsif filter_type == "more_than"
      sql_statement = "#{spend} > #{amount_1}"
    end
    return sql_statement
  end

end