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

	# Gets the last n transactions of a merchant
	# @param params A hash of parameters passed
	def DashboardMerchantQueries.get_last_transactions(params)
		query =  "SELECT t.id, t.created_at, t.referenced_user_id as user_id, " \
				 "t.amount, u.email, u.phone_number " \
				 "FROM transactions t " \
				 "INNER JOIN " \
				 "( " \
				 "SELECT MAX(t.id) as max_id, t.referenced_user_id as user_id " \
				 "FROM transactions t " \
				 "WHERE t.team_id = ? " \
				 "AND t.created_at #{DashboardMerchantQueries.get_range(params[:segment_filter])}" \
				 "DATE_SUB(now(), INTERVAL #{params[:segment_num_days]} DAY) " \
				 "GROUP BY t.referenced_user_id " \
				") t1 " \
				"ON (t1.max_id = t.id) " \
				"INNER JOIN users u ON(t.referenced_user_id = u.id) " \
				"#{DashboardMerchantQueries.get_amount_filter(
				 	params[:amt_filter], params[:amt_1], params[:amt_2])}" 
		return query
	end

	# whoever paid you in the last num_of_days
	def get_active_customers(num_of_days=14)
		Transaction.find_by_sql(["#{@@customers_query_txns} #{@@num_of_days_txns} #{num_of_days.to_s} DAY AND NOW()) HAVING COUNT(*) > 0)", self.id])
	end

	# New referres within the last 7 days
	def DashboardMerchantQueries.get_new_customers(params)
		if num_of_days.present?
			query =  "SELECT u.id AS user_id, u.email " \
					 "FROM users u, merchant_customers m " \
					 "WHERE u.id= m.customer_id " \
					 "AND m.merchant_id = ? " \
					 "AND m.created_at #{
					 	DashboardMerchantQueries.get_range(params[:segment_filter])
					 } " \
					 "DATE_SUB(now(), INTERVAL #{
					 params[:segment_num_days]} DAY)"
			return query
		else
			query = "SELECT u.id, u.email " \
					"FROM users u, merchant_customers m " \
					"WHERE u.id= m.customer_id " \
					"AND m.merchant_id = ?"
			return query
		end	
	end

	# Gets the list of active customers 
	# active customers are customers that have sent a message to the merchant
	# or had a transaction with the merchant within the last n days
	# @param num_days The number of days for which active is defined
	# @return An array of the user id, email, transaction and message times
	# of active customers.
	def DashboardMerchantQueries.get_active_customers(num_days=14)
		query = "SELECT transactions.user_id, users.email, " \
				"transactions.created_at as transaction_time " \
			 	"messages.created_at as messages_time " \
				"FROM " \
 				"( " \
				"SELECT t.referenced_user_id as user_id, t.created_at " \
				"FROM transactions t " \
				"INNER JOIN " \
				"( " \
				"SELECT MAX(t.id) as max_id, t.referenced_user_id as user_id " \
				"FROM transactions t " \
				"WHERE t.team_id = ? " \
				"GROUP BY t.referenced_user_id " \
				")t1 " \
				"ON (t1.max_id = t.id) " \
				")transactions " \
				"INNER JOIN " \
				"( " \
					"SELECT m.user_id, m.created_at " \
					"FROM messages m " \
					"INNER JOIN " \
					"( " \
					"SELECT MAX(m.id) as max_id, m.user_id " \
					"FROM messages m " \
					"WHERE m.user_id_to = ? " \
					"GROUP BY m.user_id " \
					")t1 " \
					"ON (t1.max_id = m.id) " \
				") messages " \
				"ON (transactions.user_id = messages.user_id) " \
				"INNER JOIN users ON (users.id = transactions.user_id) " \
				"WHERE transactions.created_at > DATE_SUB(now(), INTERVAL #{num_days} DAY) " \
				"OR messages.created_at > DATE_SUB(now(), INTERVAL #{num_days} DAY)"
		query
	end

	# Gets the list of inactive customers 
	# Inactive customers are customers that have not sent a message to the merchant
	# or had a transaction with the merchant within the last n days
	# @param num_days The number of days for which active is defined
	# @return An array of the user id and email of inactive customers.
	def DashboardMerchantQueries.get_inactive_customers(num_days=14)
		query = "SELECT m.customer_id, u.email " \
				"FROM merchant_customers m, users u " \
				"WHERE m.customer_id NOT IN " \
				"( " \
				"SELECT transactions.user_id " \
				"FROM " \
 				"( " \
				"SELECT t.referenced_user_id as user_id, t.created_at " \
				"FROM transactions t " \
				"INNER JOIN " \
				"( " \
				"SELECT MAX(t.id) as max_id, t.referenced_user_id as user_id " \
				"FROM transactions t " \
				"WHERE t.team_id = ? " \
			    "GROUP BY t.referenced_user_id " \
				") t1 " \
				"ON (t1.max_id = t.id) " \
				")transactions " \
				"INNER JOIN " \
				"( " \
				"SELECT m.user_id, m.created_at " \
				"FROM messages m " \
				"INNER JOIN " \
				"( " \
				"SELECT MAX(m.id) as max_id, m.user_id " \
				"FROM messages m " \
				"WHERE m.user_id_to = ? " \
				"GROUP BY m.user_id " \
				")t1 " \
				"ON (t1.max_id = m.id) " \
			") messages " \
			"ON (transactions.user_id = messages.user_id) " \
			"INNER JOIN users ON (users.id = transactions.user_id) " \
			"WHERE transactions.created_at > DATE_SUB(now(), INTERVAL #{num_days} DAY) 
			 OR messages.created_at > DATE_SUB(now(), INTERVAL #{num_days} DAY) " \
			") " \
			"AND u.id = m.customer_id" 
		query
	end

	# Gets the segment of the last messages received by a merchant
	def DashboardMerchantQueries.get_last_msg_received(params)
		query = "SELECT  m.created_at, m.user_id AS user_id, AVG(t.amount), " \
		 		"u.first_name, u.last_name " \
				"FROM messages m " \
				"INNER JOIN " \
				"( " \
				"SELECT MAX(m.id) as max_id, m.user_id "
				"FROM messages m " \
				"WHERE m.user_id_to = ? " \
				"AND m.created_at #{
					 	DashboardMerchantQueries.get_range(params[:segment_filter])
					 } " \
				"DATE_SUB(now(), INTERVAL #{params[:segment_num_days]} DAY) " \
				"GROUP BY m.user_id " \
				")t1 " \
				"ON (t1.max_id = m.id) " \
				"INNER JOIN users u ON(m.user_id = u.id) " \
				"INNER JOIN transactions t ON (t.referenced_user_id = m.user_id) " \
				"#{DashboardMerchantQueries.get_amount_filter(
				 	params[:amt_filter], params[:amt_1], params[:amt_2])} " \
				"GROUP BY t.amount, m.created_at, m.user_id_to, " \
				"u.first_name, u.last_name"
		return query
	end

	# Gets the last message sent by a merchant
	# At present this works primarily with the messages model
	def DashboardMerchantQueries.get_last_msg_sent(params)
		query = "SELECT m.user_id, m.created_at, m.user_id_to AS user_id, AVG(t.amount), " \
		 		"u.first_name, u.last_name " \
				"FROM messages m " \
				"INNER JOIN " \
				"( " \
				"SELECT MAX(m.id) as max_id, m.user_id_to " \
				"FROM messages m " \
				"WHERE m.user_id = ? " \
				"AND m.created_at #{
					 	DashboardMerchantQueries.get_range(params[:segment_filter])
					 } " \
				"DATE_SUB(now(), INTERVAL #{params[:segment_num_days]} DAY) " \
				"GROUP BY m.user_id_to " \
				")t1 " \
				"ON (t1.max_id = m.id) " \
				"INNER JOIN users u ON(m.user_id_to = u.id) " \
				"INNER JOIN transactions t ON (t.referenced_user_id = m.user_id_to) " \
				"#{DashboardMerchantQueries.get_amount_filter(
				 	params[:amt_filter], params[:amt_1], params[:amt_2])} " \
				"GROUP BY t.amount, m.user_id, " \
				"m.created_at, m.user_id_to, u.first_name, u.last_name"
		return query
	end

	# Gets new contacts from within a certain period of time
	# @param num_of_days The number of days definining the time window to retrieve new contacts
	# @param filter Used to determine what range to fetch customers for
	def DashboardMerchantQueries.get_new_contacts(num_of_days=7,filter='')
		query = "SELECT u.id, u.email " \
				"FROM users u, merchant_contacts m " \
				"WHERE u.id= m.customer_id " \
				"AND m.merchant_id = ? " \
				"AND m.created_at #{
					DashboardMerchantQueries.get_range(filter)
				} " \
				"DATE_SUB(now(), INTERVAL #{num_of_days} DAY) " 
		return query
	end

	# Gets all customers or contants of a merchant
	# @params[:segment_type] The name of the table storing the information
	# 'merchant_customers' for a merchant's customers or 
	# 'merchant_contacts' for a merchant's contacts
	def DashboardMerchantQueries.get_all_segment(params)
		table = nil 
		if (params[:segment_type == 'all_customers'])
			table = "merchant_customers"
		else
			table = "merchant_contacts"
		end
		query = "SELECT u.id as user_id, u.email " \
				"FROM users u, #{table} m " \
				"WHERE u.id= m.customer_id " \
				"AND m.merchant_id = ? " 
		return query
	end

	# Gets all contacts with accounts
	def DashboardMerchantQueries.get_contacts_without_account
		query = "SET @mid :=?; " \
				"SELECT u.id as user_id, u.email " \
				"FROM users u, merchant_contacts m " \
				"WHERE u.id= m.customer_id " \
				"AND m.merchant_id = @mid " \
				"AND m.customer_id NOT IN 
				 	(
				 	SELECT customer_id
				 	FROM merchant_customers
				 	where merchant_id = @mid 
				 	)"
		return query
	end

	# Gets contacts without accounts
	def DashboardMerchantQueries.get_contacts_with_account
		query = "SELECT u.id as user_id, u.email " \
		"FROM users u, merchant_contacts m " \
		"WHERE u.id= m.customer_id " \
		"AND m.merchant_id = ? " \
		"AND m.customer_id IN 
		 	(
		 	SELECT customer_id
		 	FROM merchant_customers
		 	where merchant_id = ? 
		 	)"
		return query
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
	def DashboardMerchantQueries.get_range(filter)
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

	# Returns a SQL statement for filtering the total amount spent by a customer
	# by amount range
	# @param filter_type The type of filter passed
	# @param amount_1 The first amount in the range
	# @param amount_2 The second amount in the range
	def DashboardMerchantQueries.get_amount_filter(filter_type, amount_1, amount_2 =0)
	    sql_statement = ""
	    spend = "WHERE t.amount"
		if filter_type == "less_than"
			sql_statement = "#{spend} < #{amount_1}"
		elsif filter_type == "between"
			sql_statement = "#{spend} >= #{amount_1} AND #{spend} < #{amount_2}"
		elsif filter_type == "exactly"
			sql_statement = "#{spend} = #{amount_1}"
		elsif filter_type == "more_than"
			sql_statement = "#{spend} > #{amount_1}"
		end
		return sql_statement
	end
			
end

