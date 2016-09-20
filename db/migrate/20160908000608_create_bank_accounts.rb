class CreateBankAccounts < ActiveRecord::Migration
  def change
    create_table :bank_accounts do |t|
      t.string :stripe_bank_account_id, index:true 
      t.string :country
      t.string :bank_name
      t.string :routing_number
      t.string :last4
      t.string :currency
      t.string :status
      t.boolean :default_for_currency
      t.boolean :livemode
      t.string :fingerprint
      t.references :user

      t.timestamps null: false
    end
  end
end
