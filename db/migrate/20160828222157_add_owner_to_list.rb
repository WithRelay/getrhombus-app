class AddOwnerToList < ActiveRecord::Migration
  def change
    add_reference :lists, :user, index: true
    add_foreign_key :lists, :users
  end
end
