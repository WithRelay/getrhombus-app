class ChangeIsActiveInUsers < ActiveRecord::Migration
  def change
  	rename_column :users, :is_active, :status
  	change_column :users, :status, :integer, default: 1 
  end
end
