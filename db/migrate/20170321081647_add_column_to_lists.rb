class AddColumnToLists < ActiveRecord::Migration
  def change
    add_column :lists, :list_type, :integer, default: 0
  end
end
