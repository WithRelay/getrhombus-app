class AddUidTypeToConversation < ActiveRecord::Migration
  def change
    add_column :conversations, :uid_type, :string
  end
end
