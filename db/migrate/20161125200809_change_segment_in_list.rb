class ChangeSegmentInList < ActiveRecord::Migration
  def change
  	change_column :lists, :segment, :text, default: nil
  end
end
