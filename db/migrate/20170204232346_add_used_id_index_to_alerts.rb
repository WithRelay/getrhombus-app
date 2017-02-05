class AddUsedIdIndexToAlerts < ActiveRecord::Migration
  def change
  	add_index :alerts, :user_id if !(index_exists?(:alerts, :user_id))
  end
end
