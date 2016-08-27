module DashboardCustomerQueries
  extend ActiveSupport::Concern

  # Any merchant you have paid or who referred you
  def get_customer_businesses
    Transaction.find_by_sql([
    "(SELECT transactions.created_at, @users_ids := users.id, users.business_name, users.email, users.business_phone, 
      SUM(transactions.amount) AS total_spend, MIN(transactions.created_at) AS first_visit, AVG(transactions.amount) AS avg_spend, 
      max(transactions.created_at) AS last_visit, users.rhombus_number,
      SUM(DATE(transactions.created_at) BETWEEN DATE_SUB(NOW(), INTERVAL 30 DAY) AND NOW()) AS last_30 
      FROM transactions  INNER JOIN users ON transactions.referenced_merchant_id = users.id
      WHERE user_id = ? GROUP BY transactions.referenced_merchant_id HAVING COUNT(*) > 0)                   

      UNION

      (SELECT created_at, id, business_name, email, business_phone, 0 as total_spend, null as first_visit, 
      0 as avg_spend, null AS last_visit, rhombus_number, 0 AS last_30 
      from users where rhombus_number = ? and id NOT IN (@users_ids))

      ORDER BY created_at DESC ", self.id, self.referrer_num])
      # and transaction_type = ?
  end

  def get_customer_transactions
    Transaction.find_by_sql([
      "SELECT users.business_name, users.email, users.rhombus_number, transactions.last_four, transactions.notes, 
        transactions.amount_less_fees, transactions.created_at, users.business_phone, transactions.transaction_number,
        transactions.transaction_uri, transactions.tax_rate, transactions.refund_id
        FROM transactions 
        INNER JOIN users ON transactions.referenced_merchant_id = users.id
        where user_id = ? ORDER BY transactions.created_at DESC", self.id])
    # and transaction_type = ?
  end 

  # Any merchant that was texted without payment and who isnt the referrer
  def get_customer_contacts
    Message.find_by_sql([
      "SELECT count(*) as total,
        users.business_name, users.email, users.business_phone, rhombus_number,
        MIN(messages.created_at) as first_conversation, 
        MAX(messages.created_at) as last_conversation
        FROM messages
        INNER JOIN users ON
        messages.user_id_to = users.id 
        WHERE messages.from = ? 
        # because they can both be null and this condition will be false...not good
        and (IFNULL(users.rhombus_number, 'a') != IFNULL(?, 'b'))
        and users.id not in (select referenced_merchant_id from transactions where user_id = ? group by referenced_merchant_id)
        GROUP BY messages.user_id_to 
        ORDER BY messages.created_at DESC", self.phone_number, self.referrer_num, self.id])
  end 

end