class RemoveApplicationFeePercentFromSubscriptions < ActiveRecord::Migration
  def change
    remove_column :subscriptions, :application_fee_percent
  end
end
