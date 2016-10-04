class RemovePageIdFromConversations < ActiveRecord::Migration
  def change
    remove_column :conversations, :page_id, :integer
    add_column :conversations, :uid, :string
  end
end
