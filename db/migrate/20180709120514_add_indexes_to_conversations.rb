class AddIndexesToConversations < ActiveRecord::Migration
  def change
  	add_index :conversations, :merchant_id
  	add_index :conversations, :uid
  	add_index :api_creds, :user_id
  end
end
