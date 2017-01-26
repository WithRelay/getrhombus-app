class AddUnreadToConversationRefs < ActiveRecord::Migration
  def change
    add_column :conversation_refs, :unread, :boolean, default: true
  end
end
