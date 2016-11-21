class DefaultCouponIdToNilInSubscriptions < ActiveRecord::Migration
  def change
  	change_column :subscriptions, :coupon_id, :integer, default: nil
  end
end
