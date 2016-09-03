class CreateAlerts < ActiveRecord::Migration
  def change
    create_table :alerts do |t|
      t.boolean :send_alert, default: true
      t.integer :interval, default: 15
      t.boolean :include_sms, default: false
      t.string :sms_number
      t.references :user
      t.timestamp :last_alert_sent_at

      t.timestamps null: false
    end
    add_foreign_key :alerts, :users
  end
end
