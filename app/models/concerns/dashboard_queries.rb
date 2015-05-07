module DashboardQueries
	extend ActiveSupport::Concern

	def get_user_transactions
		if self.user_level == 0
			transactions = Transaction.find_by_sql([
				"SELECT users.business_name, users.email, users.rhombus_number, transactions.last_four, 
					transactions.notes, transactions.amount_less_fees, transactions.created_at,
					users.business_phone, transactions.transaction_number,
					transactions.transaction_uri, transactions.tax_rate
					FROM transactions 
					INNER JOIN users ON
					transactions.referenced_merchant_id = users.id
					where user_id = ? and transaction_type = ? ORDER BY transactions.created_at DESC", self.id, 1])
		elsif self.user_level == 1
			transactions = Transaction.find_by_sql([
				"SELECT users.card_name, users.email, transactions.created_at, 
					transactions.last_four, transactions.notes, transactions.amount_less_fees, 
					users.phone_number, transactions.transaction_number,
					transactions.transaction_uri, transactions.tax_rate
					FROM transactions 
					INNER JOIN users on
					transactions.referenced_user_id = users.id
					where user_id = ? and transaction_type = ? ORDER BY transactions.created_at DESC", self.id, 2])
		end
	end	

	def get_user_customers
		if self.user_level == 0
			businesses = Transaction.find_by_sql([
				"SELECT users.business_name, users.email, users.business_phone, SUM(transactions.amount) AS total_spend,
					MIN(transactions.created_at) AS first_visit, AVG(transactions.amount) AS avg_spend, 
					max(transactions.created_at) AS last_visit,
					SUM(transactions.created_at BETWEEN DATE_SUB(NOW(), INTERVAL 30 DAY) AND NOW()) AS last_30 
					FROM transactions
					INNER JOIN users ON
					transactions.referenced_merchant_id = users.id
					WHERE user_id = ? and transaction_type = ?
					GROUP BY transactions.referenced_merchant_id ORDER BY transactions.created_at DESC", self.id, 1]);
		elsif self.user_level == 1
			customers = Transaction.find_by_sql([
				"SELECT users.card_name, users.email, users.phone_number, SUM(transactions.amount) AS total_spend,
					MIN(transactions.created_at) AS first_visit, AVG(transactions.amount) AS avg_spend, 
					max(transactions.created_at) AS last_visit,
					SUM(transactions.created_at BETWEEN DATE_SUB(NOW(), INTERVAL 30 DAY) AND NOW()) AS last_30 
					FROM transactions
					INNER JOIN users ON
					transactions.referenced_user_id = users.id
					WHERE user_id = ? and transaction_type = ?
					GROUP BY transactions.referenced_user_id ORDER BY transactions.created_at DESC", self.id, 2]);
		end
	end	

	def get_user_contacts
		if self.user_level == 0
			contacts = Message.find_by_sql([
				"SELECT count(*) as total, users.business_name, users.email, users.business_phone,
					MIN(messages.created_at) as first_conversation, 
					MAX(messages.created_at) as last_conversation
					FROM messages
					INNER JOIN users ON
					messages.user_id_to = users.id 
					WHERE user_id_from = ? GROUP BY messages.user_id_to 
					ORDER BY messages.created_at DESC", self.id]);
		elsif self.user_level == 1
			contacts = Message.find_by_sql([
				"SELECT count(*) as total, users.card_name, users.email, users.phone_number,
					MIN(messages.created_at) as first_conversation, 
					MAX(messages.created_at) as last_conversation
					FROM messages
					INNER JOIN users ON
					messages.user_id_to = users.id 
					WHERE user_id_from = ? GROUP BY messages.user_id_to 
					ORDER BY messages.created_at DESC", self.id]);
		end
	end	

	def dashboard_stats(id)
		if self.user_level == 0
			dashboard_stuff = Transaction.find_by_sql([
								'SELECT SUM(IF(created_at = CURRENT_DATE(), amount, 0)) AS todays_sales,
                                    SUM(created_at >= CURRENT_DATE()) AS todays_txn,
                                    COUNT(DISTINCT referenced_merchant_id) AS count,
                                    SUM(amount) AS sales_till_date,
                                    SUM(created_at BETWEEN DATE_SUB(NOW(), INTERVAL 30 DAY) AND NOW()) AS txn_last_30days
                                    from transactions
                                    WHERE user_id = ? and transaction_type = ?', self.id, 1])
		elsif self.user_level == 1
			dashboard_stuff = Transaction.find_by_sql([
								'SELECT SUM(IF(created_at = CURRENT_DATE(), amount_less_fees, 0)) AS todays_sales,
                                    SUM(created_at >= CURRENT_DATE()) AS todays_txn,
                                    COUNT(DISTINCT referenced_user_id) AS count,
                                    SUM(amount_less_fees) AS sales_till_date,
                                    SUM(created_at BETWEEN DATE_SUB(NOW(), INTERVAL 30 DAY) AND NOW()) AS txn_last_30days
                                    FROM transactions
                                    WHERE user_id = ? and transaction_type = ?', self.id, 2])
		end
	end

end

