class AddStripeFeeToTransactions < ActiveRecord::Migration
  def change
    add_column :transactions, :stripe_fee, :integer, after: :application_fee
    rename_column :transactions, :application_fee, :app_fee
  end
end
