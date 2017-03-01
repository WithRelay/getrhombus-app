class RenameColumnInMerchantContacts < ActiveRecord::Migration
  def change
    rename_column :merchant_contacts, :customer_id_type, :uid_type
    rename_column :merchant_contacts, :customer_id, :uid
  end
end
