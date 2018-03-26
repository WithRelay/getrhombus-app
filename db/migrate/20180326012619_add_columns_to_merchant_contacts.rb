class AddColumnsToMerchantContacts < ActiveRecord::Migration
  def change
    add_column :merchant_contacts, :first_name, :string
    add_column :merchant_contacts, :last_name, :string
    add_column :merchant_contacts, :organization, :string
    add_column :merchant_contacts, :email, :string
  end
end
