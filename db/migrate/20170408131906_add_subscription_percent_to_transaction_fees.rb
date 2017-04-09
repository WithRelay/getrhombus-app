class AddSubscriptionPercentToTransactionFees < ActiveRecord::Migration
  def change
    add_column :transaction_fees, :subscription_percent, :integer, default: 0, after: :platform_cents
  end
end
