class RenameColumnInMerchantContacts < ActiveRecord::Migration
  def change
  	remove_index :merchant_contacts, :customer_id if index_exists?(:merchant_contacts, :customer_id)
    rename_column :merchant_contacts, :customer_id_type, :uid_type
    rename_column :merchant_contacts, :customer_id, :uid
    add_index :merchant_contacts, :uid
  end
end
