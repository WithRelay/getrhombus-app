class AddStartToSubscriptions < ActiveRecord::Migration
  def change
    add_column :subscriptions, :start, :integer, after: :tax_percent
    add_column :subscriptions, :created, :integer, after: :stripe_livemode
    change_column :transaction_fees, :subscription_percent, :string
  end
end
