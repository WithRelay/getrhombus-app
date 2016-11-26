class AddCustomerIdTypeToMerchantContact < ActiveRecord::Migration
  def change
    add_column :merchant_contacts, :customer_id_type, :string
  end
end
