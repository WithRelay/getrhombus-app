class AddNameToHashtags < ActiveRecord::Migration
  def change
    add_column :hashtags, :name, :string, after: :response 
    add_index :hashtags, [:user_id, :name]
    add_index :hashtags, [:user_id, :tag]
  end
end
