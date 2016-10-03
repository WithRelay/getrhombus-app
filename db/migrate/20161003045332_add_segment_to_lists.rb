class AddSegmentToLists < ActiveRecord::Migration
  def change
    add_column :lists, :segment, :boolean
  end
end
