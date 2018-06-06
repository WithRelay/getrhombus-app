class RemoveToAndFromIndexesFromMessages < ActiveRecord::Migration
  def change
  	remove_index :messages, :from
  	remove_index :messages, :to
  end
end
