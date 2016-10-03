class AddTypeToLists < ActiveRecord::Migration
  def change
    add_column :lists, :type, :boolean
    add_index :lists, :type
  end
end
