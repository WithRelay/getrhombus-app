class CreateCustomerLists < ActiveRecord::Migration
  def change
    create_table :customer_lists do |t|
      t.string :list_references
      t.references :user, index: true

      t.timestamps null: false
    end
    add_foreign_key :customer_lists, :users
  end
end
