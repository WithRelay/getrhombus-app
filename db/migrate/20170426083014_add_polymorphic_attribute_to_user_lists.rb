class AddPolymorphicAttributeToUserLists < ActiveRecord::Migration
  def change
    remove_foreign_key :user_lists, :users
    remove_column :user_lists, :user_id
    add_column :user_lists, :customer_contact_type, :string
    add_column :user_lists, :customer_contact_id, :integer
  end
end
