class RenameResolutionInConversations < ActiveRecord::Migration
  def change
  	rename_column :conversations, :resolution, :notes
  	change_column :conversations, :notes, :text
  end
end
