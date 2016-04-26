class AddRefundIdToTransactions < ActiveRecord::Migration
  def change
    add_column :transactions, :refund_id, :integer, :default => nil
  end
end
