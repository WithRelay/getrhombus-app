class RemoveCustomerIdTypeFromMerchantCustomer < ActiveRecord::Migration
  def change
    remove_column :merchant_customers, :customer_id_type, :string
  end
end
