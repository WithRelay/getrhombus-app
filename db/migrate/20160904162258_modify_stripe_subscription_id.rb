class ModifyStripeSubscriptionId < ActiveRecord::Migration
  def change
    change_column :subscriptions, :stripe_subscription_id, :string, index: true
    change_column :coupons, :stripe_coupon_id, :string, index: true
  end
end
