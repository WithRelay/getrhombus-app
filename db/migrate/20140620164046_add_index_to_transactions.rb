class AddIndexToTransactions < ActiveRecord::Migration
  def change
  	add_index :transactions, :created_at
  	add_index :transactions, :transaction_number
  end
end
