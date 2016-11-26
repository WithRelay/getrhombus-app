class ChangeCustomerTypeInMerchantContact < ActiveRecord::Migration
  def change
  	change_column :merchant_contacts, :customer_id, :string, default: nil
  end
end
