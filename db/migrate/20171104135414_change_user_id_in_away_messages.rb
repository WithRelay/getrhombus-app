class ChangeUserIdInAwayMessages < ActiveRecord::Migration
  def change
    remove_index :away_messages, :user_id if index_exists?(:away_messages, :user_id)
    add_index :away_messages, :user_id, unique: true
  end
end
