class RemoveIndexesMigrationForMessages < ActiveRecord::Migration
  def change
  	remove_index :messages, :from
  	remove_index :messages, :to
  	remove_index :messages, :created_at
  end
end
