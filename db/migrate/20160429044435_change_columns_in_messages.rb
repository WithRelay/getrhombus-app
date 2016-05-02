class ChangeColumnsInMessages < ActiveRecord::Migration
  def change
    remove_column :messages, :status_report_req
    remove_column :messages, :scts
    remove_column :messages, :status_delivery
    remove_column :messages, :message_code
    remove_column :messages, :network_code
    rename_column :messages, :messageId, :message_id
    rename_column :messages, :err_code, :error_code
    add_column :messages, :num_segments, :string
    add_column :messages, :price_unit, :string
  end
end
