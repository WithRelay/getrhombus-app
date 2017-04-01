class ChangeDefaultValueForAccountBalanceInUsers < ActiveRecord::Migration
  def change
	change_column :users, :account_balance, :decimal, precision: 16, scale: 8, default: 2.5000000
  end
end
