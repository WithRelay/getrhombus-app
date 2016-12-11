class ChangeColumnOnInvoice < ActiveRecord::Migration
  def change
    add_column :transactions, :merchant_customer_id, :integer
    add_column :invoices, :merchant_customer_id, :integer
    remove_foreign_key :invoices, column: :team_id 
    remove_foreign_key :invoices, column: :user_id   
    remove_column :invoices, :user_id, :integer
    remove_column :invoices,:team_id, :integer
  end
end
