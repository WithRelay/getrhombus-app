class AddTimeStampsToSegments < ActiveRecord::Migration
  def change
    add_column :segments, :created_at, :datetime
    add_column :segments, :updated_at, :datetime
  end
end
