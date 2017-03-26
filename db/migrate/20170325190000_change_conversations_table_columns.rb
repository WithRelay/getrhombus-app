class ChangeConversationsTableColumns < ActiveRecord::Migration
  def change
  	remove_column :conversations, :notes
  	remove_column :conversations, :message_resolution_id
  	remove_column :conversations, :resolution
  	add_column :conversations, :is_resolved, :boolean, default: false
  end
end
