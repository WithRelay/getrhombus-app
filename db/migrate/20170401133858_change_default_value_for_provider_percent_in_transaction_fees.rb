class ChangeDefaultValueForProviderPercentInTransactionFees < ActiveRecord::Migration
  def change
  	change_column :transaction_fees, :provider_percent, :string, default: '2.9'
  end
end
