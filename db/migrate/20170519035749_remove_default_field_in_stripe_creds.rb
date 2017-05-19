class RemoveDefaultFieldInStripeCreds < ActiveRecord::Migration
  def change
    remove_column :stripe_creds, :transaction_fee_id
    remove_column :standalone_stripe_creds, :transaction_fee_id

    add_column :stripe_creds, :transaction_fee_id, :integer, { index: true, after: :user_id }
    add_column :standalone_stripe_creds, :transaction_fee_id, :integer, { index: true, after: :user_id }
  end
end
