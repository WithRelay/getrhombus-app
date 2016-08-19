class ChangeColumnsInUsers < ActiveRecord::Migration
  def change
    remove_column :users, :account_number
    remove_column :users, :account_type
    remove_column :users, :routing_number
    remove_column :users, :account_name
    remove_column :users, :approve_payments_immediately
    remove_column :users, :zip_code
    rename_column :users, :business_zip_code, :zip_code
    add_column :users, :rhombus_number_type, :string, after: :rhombus_number
    
    rename_column :messages, :user_id_from, :user_id
    change_column :messages, :user_id, :integer
    add_index :messages, :user_id
    remove_column :messages, :image_id    
  end
end
