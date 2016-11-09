class CreateMerchantCustomers < ActiveRecord::Migration
  def change
    create_table :merchant_customers do |t|
      t.integer :merchant_id
      t.integer :customer_id
    end
  end
end
