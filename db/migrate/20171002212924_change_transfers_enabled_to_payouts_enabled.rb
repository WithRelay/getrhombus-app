class ChangeTransfersEnabledToPayoutsEnabled < ActiveRecord::Migration
  def change
    rename_column :stripe_creds, :transfers_enabled, :payouts_enabled
  end
end
