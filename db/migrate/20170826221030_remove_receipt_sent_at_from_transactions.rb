class RemoveReceiptSentAtFromTransactions < ActiveRecord::Migration
  def change
    remove_column :transactions, :receipt_sent_at
  end
end
