class CreateConversationResolutions < ActiveRecord::Migration
  def change
    create_table :conversation_resolutions do |t|
    	t.integer :merchant_id, index: true
    	t.references :conversation, index: true
    	t.references :merchant_conversation_ref, index: true
        t.references :uid_conversation_ref, index: true
    	t.string :resolution, default: nil
    	t.text :notes, default: nil

    	t.timestamps null: false
    end
  end
end
