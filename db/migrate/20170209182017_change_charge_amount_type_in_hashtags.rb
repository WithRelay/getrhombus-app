class ChangeChargeAmountTypeInHashtags < ActiveRecord::Migration
  def change
  	change_column :hashtags, :charge_amount, :integer
  end
end
