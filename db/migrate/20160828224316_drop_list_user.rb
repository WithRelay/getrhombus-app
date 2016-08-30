class DropListUser < ActiveRecord::Migration
  def change
  	drop_table :lists_users
  end
end
