class AddUnreadNotificationSentToMessages < ActiveRecord::Migration
  def change
  	add_column :messages, :unread_notification_sent, :boolean, default: false
  end
end
