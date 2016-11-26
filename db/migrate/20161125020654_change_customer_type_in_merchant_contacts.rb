class ChangeCustomerTypeInMerchantContacts < ActiveRecord::Migration
  def change
  	change_column :merchant_customers, :customer_id, :string, default: nil
  end
end
