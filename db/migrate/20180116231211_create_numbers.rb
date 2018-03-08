class CreateNumbers < ActiveRecord::Migration
  def change
    create_table :numbers do |t|
      t.references :user, index: true
      t.string :number, unique: true, index: true
      t.string :provider
      t.string :type
      t.string :country
      t.integer :price
      t.boolean :default

      t.timestamps null: false
    end
    add_foreign_key :numbers, :users
  end
end
