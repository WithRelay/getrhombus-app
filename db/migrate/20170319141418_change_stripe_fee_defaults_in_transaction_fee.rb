class ChangeStripeFeeDefaultsInTransactionFee < ActiveRecord::Migration
  def change
  	drop_table :transaction_fees

  	create_table :transaction_fees do |t|
      t.string :provider
      t.string :provider_percent, default: '0.029'
      t.integer :provider_cents, default: 30
      t.string :platform_percent, default: '0'
      t.integer :platform_cents, default: 0

      t.timestamps null: false
    end

    TransactionFee.create(provider: 'stripe');
    TransactionFee.create(provider: 'stripe', provider_percent: '0.028', provider_cents: 30);

  end
end
