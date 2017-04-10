class AddCardIdToUsers < ActiveRecord::Migration
  def change
    add_column :users, :card_id, :string, after: :customer_uri
    remove_column :merchant_customers, :card_id
  end
end
