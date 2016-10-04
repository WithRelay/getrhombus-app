class RemoveNameAndUserFromSegments < ActiveRecord::Migration
  def change
  	remove_foreign_key :segments, :user
  	remove_index :segments, :user_id
  	remove_column :segments, :user_id, :users
  	remove_column :segments, :name, :string
  end
end
