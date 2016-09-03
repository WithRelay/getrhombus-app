class CreateConversationRefs < ActiveRecord::Migration
  def change
    create_table :conversation_refs do |t|
    	t.references :textable, polymorphic: true, index: true
      t.references :conversation, index: true

      t.timestamps
    end
  end
end
