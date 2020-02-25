class AddTextColumnsToMerchantContacts < ActiveRecord::Migration
  def change
    add_column :merchant_contacts, :text1, :text
    add_column :merchant_contacts, :text2, :text
    add_column :merchant_contacts, :text3, :text
    add_column :users, :text1, :text
    add_column :users, :text2, :text
    add_column :users, :text3, :text
  end
end
