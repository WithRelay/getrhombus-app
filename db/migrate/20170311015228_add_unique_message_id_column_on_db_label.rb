class AddUniqueMessageIdColumnOnDbLabel < ActiveRecord::Migration
  def change
    add_index(:fb_messages, :message_id, :unique => true) unless index_exists?(:fb_messages, :message_id)
    remove_index(:messages, :message_id)
    add_index :messages, :message_id, :unique => true
  end
end
