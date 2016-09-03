class CreateCoupons < ActiveRecord::Migration
  def change
    create_table :coupons do |t|

      t.string :name
      t.integer :amount_off
      t.string :currency
      t.string :duration
      t.integer :duration_in_months
      t.integer :max_redemptions
      t.boolean :stripe_livemode
      t.integer :percent_off
      t.integer :redeem_by



      t.timestamps null: false
    end
  end
end
