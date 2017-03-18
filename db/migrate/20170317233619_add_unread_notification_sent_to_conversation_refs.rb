class AddUnreadNotificationSentToConversationRefs < ActiveRecord::Migration
  def change
    add_column :conversation_refs, :unread_notification_sent, :boolean, default: false, after: :unread
    change_column :conversation_refs, :unread, :boolean, default: false
    remove_column :messages, :unread_notification_sent
    remove_column :messages, :unread
    remove_column :fb_messages, :unread
  end
end
