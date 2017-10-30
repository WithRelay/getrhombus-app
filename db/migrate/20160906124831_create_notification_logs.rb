class CreateNotificationLogs < ActiveRecord::Migration
  def change
    unless ActiveRecord::Base.connection.table_exists?(:notification_logs)
      create_table :notification_logs do |t|
        t.references :notifiable, polymorphic: true, index: true

        t.string :notify_type
        t.string :channel
        t.string :reason
        t.timestamps null: false
      end
    end

    remove_column :alerts, :last_alert_sent_at if ActiveRecord::Base.connection.column_exists?(:alerts, :last_alert_sent_at) # alerts now uses this class to track when alerts were last sent
  end
end
