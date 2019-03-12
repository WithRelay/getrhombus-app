class AddUpdatedIndexesToConversations < ActiveRecord::Migration
  def change
    remove_index :conversations, :uid
    add_index :conversations, [:merchant_id, :uid_type, :uid]
    add_index :user_lists, :customer_contact_id
  end
end
