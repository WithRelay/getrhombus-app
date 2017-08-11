class DropNotificationLogTable < ActiveRecord::Migration
  def change
    drop_table :notification_logs
  end
end
