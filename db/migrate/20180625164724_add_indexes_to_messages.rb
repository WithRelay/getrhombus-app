class AddIndexesToMessages < ActiveRecord::Migration
  def change
  	add_index :messages, :from
  	add_index :messages, :to
  	add_index :messages, :created_at
  end
end
