class AddOriginToList < ActiveRecord::Migration
  def change
  	add_column :lists, :origin, :integer, default: 0
  end
end
