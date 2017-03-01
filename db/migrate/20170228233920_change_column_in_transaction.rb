class ChangeColumnInTransaction < ActiveRecord::Migration
  def change
    change_column :transactions, :app_fee, :integer, :default => 0
    change_column :transactions, :stripe_fee, :integer, :default => 0
  end
end
