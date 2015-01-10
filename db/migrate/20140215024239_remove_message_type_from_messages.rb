class RemoveMessageTypeFromMessages < ActiveRecord::Migration
  def change
  	remove_column :messages, :message_type
  end
end
