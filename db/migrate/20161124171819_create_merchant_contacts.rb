class CreateMerchantContacts < ActiveRecord::Migration
  def change
    create_table :merchant_contacts do |t|
      t.integer :merchant_id, index: true
      t.integer :customer_id, index: true
      t.timestamps
    end
  end
end
