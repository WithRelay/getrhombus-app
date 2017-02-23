class AddSeperateMerchantAndCustomerColumnOnInvoices < ActiveRecord::Migration
  def change
    remove_column :invoices, :merchant_customer_id
    add_column :invoices, :team_id, :integer
    add_column :invoices, :customer_id, :integer
  end
end
