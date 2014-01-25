class AddReferencedMerchantTransactionIdToTransaction < ActiveRecord::Migration
  def change
    add_column :transactions, :referenced_merchant_transaction_id, :integer, index: true
  end
end
