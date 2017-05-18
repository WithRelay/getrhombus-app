class AddIsCustomerColOnMerchantContacts < ActiveRecord::Migration
  def change
    add_column :merchant_contacts, :is_customer, :boolean, default: false
  end
end
