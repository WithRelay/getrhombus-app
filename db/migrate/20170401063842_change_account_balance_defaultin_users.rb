class ChangeAccountBalanceDefaultinUsers < ActiveRecord::Migration
  def change
  	change_column :users, :account_balance, :decimal, precision: 16, scale: 8
  	change_column :users, :auto_reload_amt, :integer, default: 2000
  end
end
