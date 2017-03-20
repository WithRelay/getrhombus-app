class MoveRatePercentToStripeCred < ActiveRecord::Migration
  def change
  	
  	remove_column :users, :rate_percent
  	remove_column :users, :rate_cents

  	remove_column :transactions, :rate_percent
  	remove_column :transactions, :rate_cents

    create_table :transaction_fees do |t|
      t.string :provider
      t.string :provider_percent, default: '2.9'
      t.integer :provider_cents, default: 30
      t.string :platform_percent, default: '0'
      t.integer :platform_cents, default: 0

      t.timestamps null: false
    end

    TransactionFee.create(provider: 'stripe');
    TransactionFee.create(provider: 'stripe', provider_percent: '2.8', provider_cents: 30);

    add_column :stripe_creds, :transaction_fee_id, :integer, default: 1, index: true
    add_column :transactions, :transaction_fee_id, :integer, { index: true, after: :amount_less_fees, default: 1 }

  end
end
