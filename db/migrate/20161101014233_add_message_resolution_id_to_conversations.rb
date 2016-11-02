class AddMessageResolutionIdToConversations < ActiveRecord::Migration
  def change
  	add_reference(:conversations, :message_resolution, index: true, foreign_key: true)
  end
end
