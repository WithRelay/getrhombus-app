class RemoveCardTokenFromUsers < ActiveRecord::Migration
  def change
    remove_column :users, :card_token
    remove_column :users, :transactions_count
    add_column :merchant_customers, :card_id, :string, after: :customer_id
  end
end
