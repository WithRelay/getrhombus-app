class ChangeSegmentTypeInList < ActiveRecord::Migration
  def change
  	change_column :lists, :segment, :string
  end
end
