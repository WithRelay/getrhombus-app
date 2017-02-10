class RemoveMerchantCustomerIdFromTransactions < ActiveRecord::Migration
  def change
  	remove_column :transactions, :merchant_customer_id
  end
end
