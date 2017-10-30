class RemoveForeignKeyConstraints < ActiveRecord::Migration
  def change
    remove_foreign_key :alerts, column: :user_id if foreign_key_exists?(:alerts, column: :user_id)
    remove_foreign_key :invoices, column: :coupon_id if foreign_key_exists?(:invoices, column: :coupon_id)
    remove_foreign_key :invoices, column: :subscription_id if foreign_key_exists?(:invoices, column: :subscription_id)
    remove_foreign_key :invoices, column: :transaction_id if foreign_key_exists?(:invoices, column: :transaction_id)
    remove_foreign_key :subscriptions, column: :coupon_id if foreign_key_exists?(:subscriptions, column: :coupon_id)
    remove_foreign_key :subscriptions, column: :plan_id if foreign_key_exists?(:subscriptions, column: :plan_id)
    remove_foreign_key :transactions, column: :team_id if foreign_key_exists?(:subscriptions, column: :team_id)
  end
end
