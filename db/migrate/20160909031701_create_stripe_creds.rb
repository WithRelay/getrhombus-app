class CreateStripeCreds < ActiveRecord::Migration
  def change
    create_table :stripe_creds do |t|
      t.string :secret
      t.string :publishable_key
      t.string :uid, index: true
      t.string :scope
      t.boolean :livemode
      t.string :refresh_token
      t.references :user
      t.integer :uid_type
      t.string :ip
      t.integer :tos_date
      t.string :user_agent
      t.boolean :charges_enabled
      t.boolean :transfers_enabled
      t.string :disabled_reason
      t.integer :due_by
      t.string :fields_needed

      t.timestamps null: false
    end
  end
end
