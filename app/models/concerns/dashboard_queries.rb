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
				INNER JOIN users on
				transactions.user_id=users.id
				where referenced_user_id = ? and transaction_type = ? ORDER BY transactions.created_at DESC", self.id, 2])
		elsif self.user_level == 1
			transactions = Transaction.find_by_sql([
				"SELECT users.card_name, users.email, transactions.created_at, 
				transactions.last_four, transactions.notes, transactions.amount_less_fees, 
				users.phone_number, transactions.transaction_number,
				transactions.transaction_uri, transactions.tax_rate
				FROM transactions 
				INNER JOIN users on
				transactions.user_id=users.id
				where referenced_merchant_id = ? and transaction_type = ? ORDER BY transactions.created_at DESC", self.id, 1])
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
				"SELECT transactions.user_id, users.card_name, users.email, MIN(transactions.created_at) AS first_transaction, 
				SUM(transactions.amount) AS total_spend, AVG(transactions.amount) AS avg_spend, 
				users.phone_number, max(transactions.created_at) AS last_transaction,
				SUM(transactions.created_at BETWEEN DATE_SUB(NOW(), INTERVAL 30 DAY) AND NOW()) AS last_30 
				FROM messages 
				INNER JOIN users ON
				transactions.user_id = users.id
				WHERE user_id_to = ? ORDER BY users.created_at DESC", self.id]);
		elsif self.user_level == 1
			contacts = Message.find_by_sql([
				"SELECT transactions.user_id, users.card_name, users.email, MIN(transactions.created_at) AS first_visit, 
				SUM(transactions.amount) AS total_spend, AVG(transactions.amount) AS avg_spend, 
				users.phone_number, max(transactions.created_at) AS last_visit,
				SUM(transactions.created_at BETWEEN DATE_SUB(NOW(), INTERVAL 30 DAY) AND NOW()) AS last_30 
				FROM messages 
				WHERE user_id_to = ? ORDER BY users.created_at DESC", self.id]);
		end

	end	

end

