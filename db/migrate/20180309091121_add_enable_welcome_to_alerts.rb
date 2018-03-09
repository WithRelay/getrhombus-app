class AddEnableWelcomeToAlerts < ActiveRecord::Migration
  def change
    add_column :alerts, :enable_welcome, :boolean, default: true, after: :interval
  end
end
