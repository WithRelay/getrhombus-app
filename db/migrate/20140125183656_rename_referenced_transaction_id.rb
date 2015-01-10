class RenameReferencedTransactionId < ActiveRecord::Migration
  def change
  		rename_column :transactions, :referenced_transaction_id, :referenced_customer_transaction_id
  		add_index :transactions, :referenced_customer_transaction_id
  end
end
