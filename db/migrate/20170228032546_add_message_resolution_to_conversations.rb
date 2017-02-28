class AddMessageResolutionToConversations < ActiveRecord::Migration
  def change
    add_column :conversations, :resolution, :string, default: nil
  end
end
