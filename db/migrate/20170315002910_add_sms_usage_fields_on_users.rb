class AddSmsUsageFieldsOnUsers < ActiveRecord::Migration
  def change
    add_column :users, :account_balance, :integer, default: 2
    add_column :users, :auto_reload, :boolean, default: false
    add_column :users, :auto_reload_amt, :integer, default: 20
  end
end
