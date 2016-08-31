class ModifyColumnsInTransactions < ActiveRecord::Migration
  def change
    remove_column :transactions, :account_number
    remove_column :transactions, :account_type
    remove_column :transactions, :account_name
    remove_column :transactions, :routing_number
    remove_column :transactions, :zip_code
    add_column :transactions, :captured, :boolean, default: true
    add_reference :transactions, :hashtag, index: true
    add_foreign_key :transactions, :hashtags
  end
end
