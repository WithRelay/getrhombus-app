class Transaction < ActiveRecord::Base

	Balanced.configure('cb51061889c511e2ac81026ba7cd33d0') 
	
   	###### In Transaction Model
   	def balanced_debit_customer_card
   		###### Find uri from DB
   		uri = '/v1/customers/CU6vs1tjxBtifgTuzKjCGtVS'
   		customer = Balanced::Customer.find(uri)
		customer.debit(:amount => 10)
		###### handle response / save data
   	end

   	def balanced_credit_merchant_bank_account
   		####### Find uri from DB
  		uri = '/v1/customers/CU5f64LhFMO8cf7N1sQSRVOo'
   		customer = Balanced::Customer.find(uri)
   		customer.credit(:amount => 10)
   		###### handle response / save data
   	end

   	def balanced_payout_to_marketplace_bank_account
   		marketplace.owner_customer.credit(:amount => 100000, :description => "Collect revenue")
   		##### handle response and save
   	end

   	def balanced_issue_refund_to_card
   		uri = '/v1/customers/CU5f64LhFMO8cf7N1sQSRVOo'
   		customer = Balanced::Customer.find(merchant_uri)
   		customer.debit(:amount => 10)
   		#payee_uri = '/v1/customers/CU5f64LhFMO8cf7N1sQSRVOo'   		
   		#customer = Balanced::Customer.find(uri)
   		#customer.credit(:amount => 10)
   	end
 
end
