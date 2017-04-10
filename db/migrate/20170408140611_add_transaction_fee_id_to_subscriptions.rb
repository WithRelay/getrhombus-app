class AddTransactionFeeIdToSubscriptions < ActiveRecord::Migration
  def change
    add_column :subscriptions, :transaction_fee_id, :integer, index: true, after: :coupon_id
    change_column :subscriptions, :merchant_customer_id, :integer, after: :id
  end
end
