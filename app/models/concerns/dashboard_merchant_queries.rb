module DashboardMerchantQueries
	extend ActiveSupport::Concern

  #################
  # These queries need to be tmezone aware and need to use conversation model and need
  # to use referrers table where necessary


	# Customers who have paid
	@@customers_query_txns = "(SELECT transactions.created_at, @users_ids := users.id as user_id, users.card_name, users.email, 
		users.phone_number, SUM(transactions.amount) AS total_spend, MIN(transactions.created_at) AS first_visit, 
		AVG(transactions.amount) AS avg_spend, max(transactions.created_at) AS last_visit,
		SUM(transactions.created_at BETWEEN NOW() - INTERVAL 30 DAY AND NOW()) AS last_30 
		FROM transactions INNER JOIN users ON transactions.referenced_user_id = users.id
		WHERE user_id = ? "

  # this string might need grouping since we now have one to many in referrers
	@@customers_query_referrer = "(select u.created_at, u.id, u.card_name, u.email, u.phone_number, 0 as total_spend, 
																	null as first_visit, 0 as avg_spend, null AS last_visit, 0 AS last_30 
																	from referrers r
                                  inner join users u on u.id = r.referrer_id
                                  where r.referee_id = ? and u.user_level = 0 "


	@@num_of_days_txns = " and (transactions.created_at BETWEEN NOW() - INTERVAL "
	@@num_of_days_referrer = " and (created_at BETWEEN NOW() - INTERVAL "

	def get_merchant_transactions
		Transaction.find_by_sql([
			"SELECT users.card_name, users.email, transactions.created_at, transactions.last4, transactions.notes, 
			 transactions.amount_less_fees, users.phone_number, transactions.txn_number, transactions.txn_uri, 
			  transactions.tax_percent, refunds.id as refund_id
				FROM transactions 
				INNER JOIN users on transactions.referenced_user_id = users.id
				LEFT JOIN refunds on refunds.transaction_id = transactions.id
				where user_id = ? ORDER BY transactions.created_at DESC", self.id])
	end	

	# active + new with active having the higher precedence in the intersect
	def get_merchant_customers(num_of_days='')
		if num_of_days.present?
			num_of_days_txns = @@num_of_days_txns + num_of_days.to_s + " DAY AND NOW()) " 
			num_of_days_referrer = @@num_of_days_referrer + num_of_days.to_s + " DAY AND NOW()) " 
		end
		
		query = "#{@@customers_query_txns} #{num_of_days_txns} GROUP BY transactions.referenced_user_id) UNION #{@@customers_query_referrer} 
							and u.id NOT IN (@users_ids) #{num_of_days_referrer}) ORDER BY created_at DESC" 
		Transaction.find_by_sql([query, self.id, self.rhombus_number])		
	end	

	def DashboardMerchantQueries.get_last_active_transactions(num_of_days='', filter='')
		query =  "SELECT t.created_at, t.referenced_user_id as user_id, " \
				 "u.card_name, u.email, " \
				 "u.phone_number, SUM(t.amount) AS total_spend, " \
				 "MIN(t.created_at) AS first_transaction, " \
				 "AVG(t.amount) AS avg_spend, "  \
				 "MAX(t.created_at) AS last_transaction " \
				 "FROM transactions t INNER JOIN users u ON t.referenced_user_id = u.id " \
				 "WHERE t.team_id = ? " \
				 "AND t.created_at #{symbol} DATE_SUB(now(), INTERVAL #{num_of_days} DAY)"
		return query
	end

	# whoever paid you in the last num_of_days
	def get_active_customers(num_of_days=14)
		Transaction.find_by_sql(["#{@@customers_query_txns} #{@@num_of_days_txns} #{num_of_days.to_s} DAY AND NOW()) HAVING COUNT(*) > 0)", self.id])
	end

	# New referres within the last 7 days
	def DashboardMerchantQueries.get_new_customers(num_of_days=7, filter='')
		if num_of_days.present?
			query =  "SELECT u.id, u.email " \
					 "FROM users u, merchant_customers m " \
					 "WHERE u.id= m.customer_id " \
					 "AND m.merchant_id = ? " \
					 "AND m.created_at #{
					 	DashboardMerchantQueries.convert_filter(filter)
					 } " \
					 "DATE_SUB(now(), INTERVAL #{num_of_days} DAY)"
			return query
		else
			query = "SELECT u.id, u.email " \
					"FROM users u, merchant_customers m " \
					"WHERE u.id= m.customer_id " \
					"AND m.merchant_id = ?"
			return query
		end	
	end

	# only inbound
  # user_id_to and user_id are going away so don't use them
	def get_merchant_contacts_without_signups
		Message.find_by_sql([
			"SELECT count(*) as total, to, 
				MIN(messages.created_at) as first_conversation, 
				MAX(messages.created_at) as last_conversation
				FROM messages 
				WHERE ((user_id = 0 or user_id is null) and user_id_to = ?) 
				GROUP BY messages.from
				ORDER BY messages.created_at DESC", self.id])
	end	

	def dashboard_stats
		if self.user_level == 0
			Transaction.find_by_sql([
				'SELECT SUM(IF(DATE(t.created_at) >= curdate(), amount, 0)) AS todays_sales,
	                SUM(DATE(t.created_at) >= curdate()) AS todays_txn,
	                COUNT(DISTINCT team_id) AS count,
	                SUM(amount) AS sales_till_date,
	                SUM(DATE(t.created_at) BETWEEN DATE_SUB(curdate(), INTERVAL 30 DAY) AND curdate()) AS txn_last_30days
	                from transactions t
	                LEFT JOIN refunds on refunds.transaction_id = t.id
	                WHERE user_id = ? and refunds.id is NULL', self.id])
			#and transaction_type = ?
		elsif self.user_level == 1
			Transaction.find_by_sql([
				'SELECT SUM(IF(DATE(t.created_at) >= curdate(), amount_less_fees, 0)) AS todays_sales,
	                SUM(DATE(t.created_at) >= curdate()) AS todays_txn,
	                COUNT(DISTINCT referenced_user_id) AS count,
	                SUM(amount) AS sales_till_date,
	                SUM(DATE(t.created_at) BETWEEN DATE_SUB(curdate(), INTERVAL 30 DAY) AND curdate()) AS txn_last_30days
	                from transactions t
	                LEFT JOIN refunds on refunds.transaction_id = t.id
	                WHERE user_id = ? and refunds.id is NULL', self.id])
		end
	end

	def get_total_messages
		return Message.where("user_id = ? and DATE(created_at) BETWEEN DATE_SUB(curdate(), INTERVAL 30 DAY) AND curdate()", self.id).count if self.user_level == 0
		Message.where("user_id = ? or user_id_to = ? and DATE(created_at) BETWEEN DATE_SUB(curdate(), 
							INTERVAL 30 DAY) AND curdate()", self.id, self.id).count if self.user_level == 1
	end

	def get_line_stats
		if self.user_level == 0
			Transaction.find_by_sql([
				'select count(*) as num_of_txns, sum(amount) as day_total,
					date_format(date(t.created_at), "%b %e") as day 
					from transactions t 
					LEFT JOIN refunds on refunds.transaction_id = t.id
					where user_id = ?
					and refunds.id is NULL and DATE(t.created_at) BETWEEN DATE_SUB(curdate(), INTERVAL 7 DAY) AND curdate() 	
					GROUP BY DAY(t.created_at)', self.id])
		elsif self.user_level == 1
			Transaction.find_by_sql([
				'select count(*) as num_of_txns, sum(amount_less_fees) as day_total,
					date_format(date(t.created_at), "%b %e") as day 
					from transactions t where user_id = ?
					LEFT JOIN refunds on refunds.transaction_id = t.id
					and refunds.id is NULL and DATE(t.created_at) BETWEEN DATE_SUB(curdate(), INTERVAL 7 DAY) AND curdate() 
					GROUP BY DAY(t.created_at)', self.id])
		end
	end

	def get_area_stats
		if self.user_level == 0
			Transaction.find_by_sql([
				'select sum(amount) as week_total,
					date_format(date(t.created_at), "%b %e") as week_day from transactions t
					where user_id = ?
					LEFT JOIN refunds on refunds.transaction_id = t.id
					and refunds.id is NULL and DATE(t.created_at) BETWEEN DATE_SUB(curdate(), INTERVAL 30 DAY) AND curdate() 	
					GROUP BY WEEk(t.created_at)', self.id])
		elsif self.user_level == 1
			Transaction.find_by_sql([
				'select sum(amount_less_fees) as week_total,
					date_format(date(t.created_at), "%b %e") as week_day from transactions t
					where user_id = ?
					LEFT JOIN refunds on refunds.transaction_id = t.id
					and refunds.id is NULL and DATE(t.created_at) BETWEEN DATE_SUB(curdate(), INTERVAL 30 DAY) AND curdate() 
					GROUP BY WEEK(t.created_at)', self.id])
		end
	end

	private
	def DashboardMerchantQueries.convert_filter(filter)
		symbol = ''
		if filter == "more_than"
			symbol = "<"
		elsif filter == "exactly"
			symbol = "="
		elsif filter == "less_than"
			symbol = ">"
		end
		return symbol
	end	

end

