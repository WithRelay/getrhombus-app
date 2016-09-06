class ModifyColumnsInTransaction < ActiveRecord::Migration
  def change
    rename_column :transactions, :expiration_month, :exp_month
    rename_column :transactions, :expiration_year, :exp_year
    rename_column :transactions, :transaction_uri, :txn_uri
    rename_column :transactions, :transaction_number, :txn_number
    rename_column :transactions, :transaction_available_at, :txn_available_at
    change_column :transactions, :amount_with_taxes, :decimal, precision: 8, scale: 2, after: :amount
    change_column :transactions, :tax_percent, :string, after: :amount_with_taxes
    change_column :transactions, :rhombus_fee, :decimal, precision: 8, scale: 2, after: :tax_percent
    change_column :transactions, :amount_less_fees, :decimal, precision: 8, scale: 2, after: :rhombus_fee
    change_column :transactions, :txn_uri, :string, after: :amount_less_fees
    rename_column :transactions, :on_behalf_of_uri, :destination
  end
end
