class AddFieldsToSubscriptions < ActiveRecord::Migration
  def change
    add_column :subscriptions, :ended_at, :integer, after: :current_period_end
    add_column :subscriptions, :canceled_at, :integer, after: :current_period_end
    add_column :subscriptions, :cancel_at_period_end, :boolean
    change_column :subscriptions, :cancel_at_period_end, :boolean, after: :canceled_at
  end
end
