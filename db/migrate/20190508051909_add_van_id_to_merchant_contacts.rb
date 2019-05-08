class AddVanIdToMerchantContacts < ActiveRecord::Migration
  def change
    add_column :merchant_contacts, :van_id, :string
  end
end
