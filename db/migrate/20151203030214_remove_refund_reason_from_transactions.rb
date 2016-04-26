class RemoveRefundReasonFromTransactions < ActiveRecord::Migration
  def change
  	remove_column :transactions, :refund_reason
  end
end
