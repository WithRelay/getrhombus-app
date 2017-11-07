class ChangeTransactionFeeDefaultInStripeCreds < ActiveRecord::Migration
  def change
    change_column :stripe_creds, :transaction_fee_id, :integer, default: 3
    change_column :transactions, :transaction_fee_id, :integer
  end
end
