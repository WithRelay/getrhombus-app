class RedoNameIndexesInPlansAndCoupons < ActiveRecord::Migration
  def change
  	remove_index :coupons, :name
  	remove_index :plans, :name

  	add_index :plans, [:user_id, :name], unique: true
	add_index :coupons, [:user_id, :name], unique: true
  end
end
