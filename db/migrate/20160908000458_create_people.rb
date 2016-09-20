class CreatePeople < ActiveRecord::Migration
  def change
    create_table :people do |t|
      t.string :first_name
      t.string :last_name
      t.string :role
      t.string :dob
      t.string :last4
      t.string :stripe_pii_id, index: true
      t.boolean :livemode
      t.references :user

      t.timestamps null: false
    end
  end
end
