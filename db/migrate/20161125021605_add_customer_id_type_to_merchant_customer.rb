class AddCustomerIdTypeToMerchantCustomer < ActiveRecord::Migration
  def change
    add_column :merchant_customers, :customer_id_type, :string
  end
end
