class AddCurrencyToTransactions < ActiveRecord::Migration
  def change
    add_column :transactions, :currency, :string, :default => "usd"
  end
end
