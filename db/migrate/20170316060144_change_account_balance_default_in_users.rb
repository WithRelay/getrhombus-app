class ChangeAccountBalanceDefaultInUsers < ActiveRecord::Migration
  def change
  	 change_column :users, :account_balance, :integer, default: 2
  end
end
