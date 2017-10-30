class AddChannelIdToNotificationLogs < ActiveRecord::Migration
  def change
    add_column :notification_logs, :channel_id, :integer, after: :channel unless column_exists? :notification_logs, :channel_id
    add_index :notification_logs, :channel_id unless index_exists? :notification_logs, :channel_id
  end
end
