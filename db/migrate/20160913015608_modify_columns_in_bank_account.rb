class ModifyColumnsInBankAccount < ActiveRecord::Migration
  def change
    add_column :bank_accounts, :institution_number, :string, default: '', after: :routing_number
    rename_column :bank_accounts, :last4, :account_number
    change_column :bank_accounts, :account_number, :string, after: :bank_name
    rename_column :referrers, :business_name, :org_name
  end
end
