class AddIndexToListNameAndUserId < ActiveRecord::Migration
  def change
  	add_index :lists, [:user_id, :name], unique: true
  end
end
