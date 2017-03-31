class CreateStandaloneStripeCreds < ActiveRecord::Migration
  def change
    create_table :standalone_stripe_creds do |t|
    	t.string :email
    	t.string :account_id, index: true
    	t.string :secret
      t.string :publishable_key
      t.string :scope
      t.boolean :livemode
      t.string :refresh_token
      t.references :user, index: true
      t.references :transaction_fee, index: true, default: 2

      t.timestamps null: false
    end

    remove_column :stripe_creds, :uid_type
    remove_column :stripe_creds, :uid
    remove_column :stripe_creds, :email
    change_column :stripe_creds, :account_id, :string, after: :id
  end
end
