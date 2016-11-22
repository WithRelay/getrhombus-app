class AddIndexToCouponAndPlanNames < ActiveRecord::Migration
  def change
  	add_index :plans, :name, unique: true
	add_index :coupons, :name, unique: true
  end
end
