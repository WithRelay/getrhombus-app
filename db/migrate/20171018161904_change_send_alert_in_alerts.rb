class ChangeSendAlertInAlerts < ActiveRecord::Migration
  def change
    change_column :alerts, :send_alert, :boolean, default: 0 
  end
end
