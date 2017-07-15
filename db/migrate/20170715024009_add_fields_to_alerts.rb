class AddFieldsToAlerts < ActiveRecord::Migration
  def change
    rename_column :alerts, :sms_number, :sms_numbers
    change_column :alerts, :sms_numbers, :text
    add_column :alerts, :emails, :text, after: :sms_numbers
  end
end
