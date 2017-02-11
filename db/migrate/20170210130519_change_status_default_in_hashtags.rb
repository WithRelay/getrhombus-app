class ChangeStatusDefaultInHashtags < ActiveRecord::Migration
  def change
  	change_column :hashtags, :status, :integer, default: 1
  end
end
