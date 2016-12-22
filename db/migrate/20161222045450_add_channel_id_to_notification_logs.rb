class AddChannelIdToNotificationLogs < ActiveRecord::Migration
  def change
    add_column :notification_logs, :channel_id, :integer, after: :channel
    add_index :notification_logs, :channel_id
  end
end
