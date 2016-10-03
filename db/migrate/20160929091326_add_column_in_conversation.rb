class AddColumnInConversation < ActiveRecord::Migration
  def change
    add_column :conversations, :page_id, :integer
    add_column :conversations, :resolution, :boolean
  end
end
