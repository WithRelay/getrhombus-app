module DashboardCustomerQueries
  extend ActiveSupport::Concern

  # Any merchant you have paid or who referred you
  def get_customer_businesses
    Transaction.find_by_sql([
    "(SELECT t.created_at, @users_ids := users.id, users.org_name, users.email, users.org_phone, 
      SUM(t.amount) AS total_spend, MIN(t.created_at) AS first_visit, AVG(transactions.amount) AS avg_spend, 
      max(t.created_at) AS last_visit, users.rhombus_number,
      SUM(DATE(t.created_at) BETWEEN DATE_SUB(NOW(), INTERVAL 30 DAY) AND NOW()) AS last_30 
      FROM transactions t INNER JOIN users ON transactions.team_id = users.id
      WHERE user_id = ? GROUP BY t.team_id HAVING COUNT(*) > 0)                   

      UNION

      (SELECT u.created_at, u.id, org_name, u.email, org_phone, 0 as total_spend, null as first_visit, 
      0 as avg_spend, null AS last_visit, rhombus_number, 0 AS last_30 
      from referrers r 
      inner join users u on u.id = r.referrer_id 
      where r.referee_id = ? and u.user_level = 1 and u.id NOT IN (@users_ids))

      ORDER BY created_at DESC ", self.id, self.id])
  end

  def get_customer_transactions
    Transaction.find_by_sql([
      "SELECT users.org_name, users.email, users.rhombus_number, transactions.last_four, transactions.notes, 
        transactions.amount_less_fees, t.created_at, users.org_phone, transactions.transaction_number,
        transactions.transaction_uri, transactions.tax_percent, refunds.id as refund_id
        FROM transactions t
        INNER JOIN users ON transactions.team_id = users.id
        LEFT JOIN refunds on refunds.transaction_id = transactions.id
        where user_id = ? ORDER BY t.created_at DESC", self.id])
  end 

  # Any merchant that was texted without payment and who isnt the referrer
  def get_customer_contacts
    Message.find_by_sql([
      "SELECT count(*) as total,
        u.org_name, u.email, u.org_phone, rhombus_number,
        MIN(m.created_at) as first_conversation, 
        MAX(m.created_at) as last_conversation
        FROM messages m
        INNER JOIN users u ON m.user_id_to = u.id 
        LEFT JOIN referrers r on r.referrer_id = u.id and r.referee_id = ?
        LEFT JOIN transactions t on u.id = t.team_id and t.user_id = ?
        WHERE m.from = ?         
        and r.referrer_id is null 
        and t.team_id is null 
        GROUP BY m.user_id_to 
        ORDER BY m.created_at DESC", self.id, self.id, self.phone_number])
  end 

end