class AddFeeTypeToTransactionFees < ActiveRecord::Migration
  def change
    add_column :transaction_fees, :fee_type, :integer, default: 1, after: :subscription_percent
  end
end
