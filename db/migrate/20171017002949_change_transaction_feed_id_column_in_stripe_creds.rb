class ChangeTransactionFeedIdColumnInStripeCreds < ActiveRecord::Migration
  def change
    change_column :stripe_creds, :transaction_fee_id, :integer, default: 2
    change_column :transaction_fees, :provider_percent, :string, default: "2.8"
  end
end
