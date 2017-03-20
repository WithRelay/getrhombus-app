class AddColumnsOnTransactionsTable < ActiveRecord::Migration
  def change
    add_column :transactions, :rate_percent, :string, default: '2.9'
    add_column :transactions, :rate_cents, :integer, default: 30
  end
end
