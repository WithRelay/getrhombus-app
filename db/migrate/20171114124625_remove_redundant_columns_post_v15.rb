class RemoveRedundantColumnsPostV15 < ActiveRecord::Migration
  def change
    remove_column :users, :customer_uri
    remove_column :users, :referrer_num
    remove_column :users, :first_name
    remove_column :users, :last_name
    remove_column :users, :provider
    remove_column :users, :stripe_scope
    remove_column :users, :stripe_refresh_token
    remove_column :users, :stripe_publishable_key
    remove_column :users, :stripe_access_token
    remove_column :users, :uid
    remove_column :users, :zip_code
    remove_column :users, :street_address
    remove_column :users, :city
    remove_column :users, :state_province
    remove_column :users, :country
    remove_column :transactions, :referenced_customer_transaction_id
    remove_column :transactions, :referenced_merchant_transaction_id
    remove_column :transactions, :referenced_user_id
    remove_column :transactions, :transaction_type
    remove_column :transactions, :amount_less_fees
  end
end
