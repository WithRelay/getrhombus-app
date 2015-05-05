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
				where referenced_user_id = ? and transaction_type = ? ORDER BY created_at DESC", self.id, 2])
		elsif self.user_level == 1
			transactions = Transaction.find_by_sql([
				"SELECT users.card_name, users.email, transactions.created_at, 
				transactions.last_four, transactions.notes, transactions.amount_less_fees, 
				users.phone_number, transactions.transaction_number,
				transactions.transaction_uri, transactions.tax_rate
				FROM transactions 
				INNER JOIN users on
				transactions.user_id=users.id
				where referenced_merchant_id = ? and transaction_type = ? ORDER BY created_at DESC", self.id, 1])
		end
	end	


	def get_user_customers
		if self.user_level == 0
			transactions = Transaction.find_by_sql([
				"SELECT users.business_name, users.email, users.rhombus_number, transactions.last_four, 
				transactions.notes, transactions.amount_less_fees, transactions.created_at,
				users.business_phone, transactions.transaction_number,
				transactions.transaction_uri, transactions.tax_rate
				FROM transactions 
				INNER JOIN users on
				transactions.user_id=users.id
				where referenced_user_id = ? and transaction_type = ? ORDER BY created_at DESC", self.id, 2])
		elsif self.user_level == 1
			transactions = Transaction.find_by_sql([
				"SELECT users.card_name, users.email, transactions.created_at, 
				transactions.last_four, transactions.notes, transactions.amount_less_fees, 
				users.phone_number, transactions.transaction_number,
				transactions.transaction_uri, transactions.tax_rate
				FROM transactions 
				INNER JOIN users on
				transactions.user_id=users.id
				where referenced_merchant_id = ? and transaction_type = ? ORDER BY created_at DESC", self.id, 1])
		end
	end	
end

