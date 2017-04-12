module DashboardMerchantQueries
	extend ActiveSupport::Concern

	#################
	# These queries need to be tmezone aware and need to use conversation model and need
	# to use referrers table where necessary

	def segment_dynamic_customers
		"MerchantCustomer.where('created_at >= ? AND merchant_id = ?', Time.current - 7.days, #{self.id}).pluck(:uid)"
  end

  def segment_dynamic_contacts
  	"MerchantContact.where('created_at >= ? AND merchant_id = ?', Time.current - 7.days, #{self.id})"
  end

  def new_segment_customers
    merchant_id = self.id
   %Q{Transaction.where("created_at >= ? AND user_id IN(?) AND team_id = ?", Time.current - 30.days,
      MerchantCustomer.where(merchant_id: #{merchant_id}).pluck(:customer_id), #{merchant_id}).pluck(:user_id) |
      FbMessage.where("created_at >=? AND user_id_to = ? AND user_id IN(?)", Time.current - 30.days,
      #{merchant_id}, MerchantCustomer.where(merchant_id: #{merchant_id}).pluck(:customer_id)).pluck(:user_id)}
  end

  def new_segment_contacts
  	merchant_id = self.id
  	%Q{FbMessage.where("created_at >= ? AND user_id_to = ?", Time.current - 30.days,
      #{merchant_id}).where(from: MerchantContact.where(merchant_id: #{merchant_id}).pluck(:uid))}
  end

	# Customers who have paid
	@@customers_query_txns = "(SELECT transactions.created_at, @users_ids := users.id as user_id, users.card_name, users.email,
		users.phone_number, SUM(transactions.amount) AS total_spend, MIN(transactions.created_at) AS first_visit,
		AVG(transactions.amount) AS avg_spend, max(transactions.created_at) AS last_visit,
		SUM(transactions.created_at BETWEEN NOW() - INTERVAL 30 DAY AND NOW()) AS last_30
		FROM transactions INNER JOIN users ON transactions.referenced_user_id = users.id
		WHERE user_id = ? "


	@@num_of_days_txns = " and (transactions.created_at BETWEEN NOW() - INTERVAL "


	# Gets the last n transactions of a merchant
	# @param params A hash of parameters passed
	def DashboardMerchantQueries.get_last_transactions(params)
		query =  "SELECT t.id, t.created_at, t.referenced_user_id as user_id, " \
				 "t.amount, u.email, u.phone_number, u.first_name, u.last_name " \
				 "FROM transactions t " \
				 "INNER JOIN " \
				 "( " \
				 "SELECT MAX(t.id) as max_id, t.referenced_user_id as user_id " \
				 "FROM transactions t " \
				 "WHERE t.team_id = :id " \
				 "AND t.created_at #{DashboardMerchantQueries.get_range(params[:segment_filter])}" \
				 "DATE_SUB('#{params[:current_time]}', INTERVAL #{params[:segment_num_days]} DAY) " \
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
		if params[:segment_num_days].present?
			query =  "SELECT u.id, u.first_name, u.last_name, u.phone_number, u.email " \
					 "FROM users u, merchant_customers m " \
					 "WHERE u.id= m.customer_id " \
					 "AND m.merchant_id = :id " \
					 "AND m.created_at #{
					 	DashboardMerchantQueries.get_range(params[:segment_filter])
					 } " \
					 "DATE_SUB('#{params[:current_time]}', " \
					 "INTERVAL #{params[:segment_num_days]} DAY)"
			return query
		else
			query = "SELECT u.id, u.email, u.first_name, u.last_name " \
					"u.phone_number " \
					"FROM users u, merchant_customers m " \
					"WHERE u.id= m.customer_id " \
					"AND m.merchant_id = :id"
			return query
		end
	end

	# Gets the list of active customers
	# active customers are customers that have sent a message to the merchant
	# or had a transaction with the merchant within the last n days
	# @param num_days The number of days for which active is defined
	# @return An array of the user id, email, transaction and message times
	# of active customers.
	def DashboardMerchantQueries.get_active_customers(params)
		num_days = params[:segment_num_days]
		query = "SELECT transactions.user_id, users.email, users.first_name " \
				"users.last_name, users.phone_number " \
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
				"WHERE t.team_id = :id " \
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
					"WHERE m.user_id_to = :id " \
					"GROUP BY m.user_id " \
					")t1 " \
					"ON (t1.max_id = m.id) " \
				") messages " \
				"ON (transactions.user_id = messages.user_id) " \
				"INNER JOIN users ON (users.id = transactions.user_id) " \
				"WHERE transactions.created_at > DATE_SUB('#{params[:current_time]}', INTERVAL #{num_days} DAY) " \
				"OR messages.created_at > DATE_SUB('#{params[:current_time]}', INTERVAL #{num_days} DAY)"
		query
	end

	# Gets the list of inactive customers
	# Inactive customers are customers that have not sent a message to the merchant
	# or had a transaction with the merchant within the last n days
	# @return An array of the user id and email of inactive customers.
	def DashboardMerchantQueries.get_inactive_customers(params)
		num_days = params[:segment_num_days]
		query = "SELECT m.customer_id, u.id, u.first_name, u.last_name, " \
		 		"u.phone_number, u.email " \
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
				"WHERE t.team_id = :id " \
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
				"WHERE m.user_id_to = :id " \
				"GROUP BY m.user_id " \
				")t1 " \
				"ON (t1.max_id = m.id) " \
			") messages " \
			"ON (transactions.user_id = messages.user_id) " \
			"INNER JOIN users ON (users.id = transactions.user_id) " \
			"WHERE transactions.created_at > DATE_SUB('#{params[:current_time]}', INTERVAL #{num_days} DAY)
			 OR messages.created_at > DATE_SUB('#{params[:current_time]}', INTERVAL #{params[:segment_num_days]} DAY) " \
			") " \
			"AND u.id = m.customer_id"
		query
	end

	# Gets the segment of the last messages received by a merchant
	def DashboardMerchantQueries.get_last_msg_received(params)
		query = "SELECT u.id, m.created_at, AVG(t.amount), " \
		 		"u.first_name, u.last_name " \
				"FROM messages m " \
				"INNER JOIN " \
				"( " \
				"SELECT MAX(m.id) as max_id, m.user_id "
				"FROM messages m " \
				"WHERE m.user_id_to = :id " \
				"AND m.created_at #{
					 	DashboardMerchantQueries.get_range(params[:segment_filter])
					 } " \
				"DATE_SUB('#{params[:current_time]}', INTERVAL #{params[:segment_num_days]} DAY) " \
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

	# Creates a segment for a plan
	# @param plan_id The id of the plan for which a segment is to be
	def DashboardMerchantQueries.get_plan_users(plan_id)
		query = "SELECT u.id, u.email AS email, " \
		 		"u.first_name, u.last_name, u.phone_number " \
				"FROM merchant_customers m " \
				"INNER JOIN users u " \
				"ON (u.id = m.customer_id) "\
				"WHERE m.customer_id IN ( "  \
					"SELECT s.merchant_customer_id " \
					"FROM subscriptions s " \
					"where s.plan_id = #{plan_id} " \
					") "
		return query
	end

	# Gets the last message sent by a merchant
	# At present this works primarily with the messages model
	def DashboardMerchantQueries.get_last_msg_sent(params)
		query = "SELECT m.created_at, u.id, AVG(t.amount), " \
		 		"u.first_name, u.last_name, u.phone_number " \
				"FROM messages m " \
				"INNER JOIN " \
				"( " \
				"SELECT MAX(m.id) as max_id, m.user_id_to " \
				"FROM messages m " \
				"WHERE m.user_id = :id " \
				"AND m.created_at #{
					 	DashboardMerchantQueries.get_range(params[:segment_filter])
					 } " \
				"DATE_SUB('#{params[:current_time]}', INTERVAL #{params[:segment_num_days]} DAY) " \
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
		query = "SELECT u.id, u.email, u.first_name, u.last_name, u.phone_number " \
				"FROM users u, merchant_contacts m " \
				"WHERE u.id= m.customer_id " \
				"AND m.merchant_id = :id " \
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
		query = "SELECT u.id, u.first_name, u.last_name u.email, u.phone_number " \
				"FROM users u, #{table} m " \
				"WHERE u.id= m.customer_id " \
				"AND m.merchant_id = :id "
		return query
	end

	# Gets all contacts with accounts
	def DashboardMerchantQueries.get_contacts_without_account
		query = "SELECT u.id, u.email, u.first_name, u.last_name, " \
				"u.phone_number, u.last_name " \
				"FROM users u, merchant_contacts m " \
				"WHERE u.id= m.customer_id " \
				"AND m.merchant_id = :id " \
				"AND m.customer_id NOT IN
				 	(
				 	SELECT customer_id
				 	FROM merchant_customers
				 	where merchant_id = :id
				 	)"
		return query
	end

	# Gets contacts without accounts
	def DashboardMerchantQueries.get_contacts_with_account
		query = "SELECT u.id, u.email, u.first_name, u.last_name " \
		"FROM users u, merchant_contacts m " \
		"WHERE u.id= m.customer_id " \
		"AND m.merchant_id = :id " \
		"AND m.customer_id IN
		 	(
		 	SELECT customer_id
		 	FROM merchant_customers
		 	where merchant_id = :id
		 	)"
		return query
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
