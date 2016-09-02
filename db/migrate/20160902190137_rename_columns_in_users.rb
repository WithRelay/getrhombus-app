class RenameColumnsInUsers < ActiveRecord::Migration
  def change
    rename_column :users, :tax_rate, :tax_percent
    remove_column :users, :subscription_type
  end
end
