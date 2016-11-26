class ChangeCustomerTypeInMerchantCustomer < ActiveRecord::Migration
  def change
  	change_column :merchant_customers, :customer_id, :integer, default: nil
  end
end
