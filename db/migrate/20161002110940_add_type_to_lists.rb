class AddTypeToLists < ActiveRecord::Migration
  def change
    add_column :lists, :type, :boolean, default: false
    add_index :lists, :type
  end
end
