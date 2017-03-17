class CreateAccountReloads < ActiveRecord::Migration
  def change
    create_table :account_reloads do |t|
      t.integer :user_id
      t.integer :transaction_id
      t.integer :origin

      t.timestamps null: false
    end
  end
end
