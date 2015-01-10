class AddFieldsToMessages < ActiveRecord::Migration
  def change
    add_column :messages, :from, :string
    add_column :messages, :to, :string
    add_column :messages, :status_report_req, :integer
    add_column :messages, :message_timestamp, :string
    add_column :messages, :message_type, :integer
    add_column :messages, :message_price, :decimal
    add_column :messages, :scts, :string
    add_column :messages, :client_ref, :string
    add_column :messages, :status, :string
    add_column :messages, :status_delivery, :string
    add_column :messages, :network_code, :string
    add_column :messages, :error_text, :string
    add_column :messages, :err_code, :string
    add_column :messages, :message_code, :integer

    add_column :messages, :user_id_from, :integer, index: true
    add_column :messages, :user_id_to, :integer, index: true
    add_reference :messages, :transaction, index: true
  end
end
