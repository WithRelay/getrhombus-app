class AddReferencedMerchantIdToTransaction < ActiveRecord::Migration
  def change
    add_column :transactions, :referenced_merchant_id, :integer, index: true
  end
end
