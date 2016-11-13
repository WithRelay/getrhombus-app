class CreateMerchantCustomers < ActiveRecord::Migration
  def change
    create_table :merchant_customers do |t|
      t.integer :merchant_id, index: true
      t.integer :customer_id, index: true
      t.timestamps null: false
    end
  end
end
