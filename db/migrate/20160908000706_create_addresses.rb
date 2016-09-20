class CreateAddresses < ActiveRecord::Migration
  def change
    create_table :addresses do |t|
      t.string :street_address
      t.string :city
      t.string :state_province
      t.string :country
      t.string :postal_code
      t.references :addressable, polymorphic: true, index: true

      t.timestamps null: false
    end
  end
end
