class ModifyColumnsInBankAccounts < ActiveRecord::Migration
  def change
    add_index :bank_accounts, :fingerprint
    change_column :bank_accounts, :default_for_currency, :boolean, default: true
  end
end
