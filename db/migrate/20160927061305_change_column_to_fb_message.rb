class ChangeColumnToFbMessage < ActiveRecord::Migration
  def change
    add_column :fb_messages, :seq, :integer
    change_column :fb_messages, :time_stamp, :datetime
  end
end
