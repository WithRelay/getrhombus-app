class ChangeStripeSubscriptionModel < ActiveRecord::Migration
  def change
    add_column :subscriptions, :merchant_customer_id, :integer
    add_column :merchant_customers, :stripe_customer_id, :string
    remove_foreign_key :subscriptions, column: :team_id 
    remove_foreign_key :subscriptions, column: :user_id   
    remove_column :subscriptions, :user_id, :integer
    remove_column :subscriptions,:team_id, :integer
  end
end
