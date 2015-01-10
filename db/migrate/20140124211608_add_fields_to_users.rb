class AddFieldsToUsers < ActiveRecord::Migration
  def change
    add_column :users, :name, :string
    add_column :users, :user_level, :integer
    add_column :users, :customer_uri, :string

    add_column :users, :last_four, :string
    add_column :users, :expiration_month, :string
    add_column :users, :expiration_year, :string
    add_column :users, :zip_code, :string
    add_column :users, :card_name, :string
    add_column :users, :card_type, :string
    add_column :users, :phone_number, :string, :unique => true

    add_column :users, :business_name, :string
    add_column :users, :business_type, :string
    add_column :users, :street_address, :string
    add_column :users, :apt_suite, :string
    add_column :users, :city, :string
    add_column :users, :state_province, :string
    add_column :users, :business_phone, :string
    add_column :users, :country, :string
    add_column :users, :rhombus_number, :string, :unique => true
    
    add_column :users, :routing_number, :string
    add_column :users, :account_name, :string
    add_column :users, :account_number, :string
    add_column :users, :account_type, :string
    add_column :users, :approve_payments_immediately, :boolean, default: false
    add_column :users, :tax_rate, :string, default: "0"

    add_column :users, :transactions_count, :integer
    #add_column :users, :messages_count, :integer
 
    add_index :users, :phone_number, :unique => true
    add_index :users, :rhombus_number, :unique => true

    #add_reference :products, :user, index: true
  end
end
