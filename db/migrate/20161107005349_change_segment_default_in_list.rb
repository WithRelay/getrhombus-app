class ChangeSegmentDefaultInList < ActiveRecord::Migration
  def change
  	change_column :lists, :segment, :string, default: nil
  end
end
