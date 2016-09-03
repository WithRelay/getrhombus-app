class AddStripeSubscriptionIdToSubscriptions < ActiveRecord::Migration
  def change
    add_column :subscriptions, :stripe_subscription_id, :integer, after: :id
  end
end
