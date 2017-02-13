class AddSourceToConversationRefs < ActiveRecord::Migration
  def change
    add_column :conversation_refs, :source, :integer
  end
end
