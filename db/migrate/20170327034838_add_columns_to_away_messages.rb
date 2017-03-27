class AddColumnsToAwayMessages < ActiveRecord::Migration
  def change
    add_column :away_messages, :enabled, :boolean
    add_column :away_messages, :response, :text
    execute "ALTER TABLE away_messages MODIFY response TEXT CHARACTER SET utf8mb4 COLLATE utf8mb4_bin"
  end
end
