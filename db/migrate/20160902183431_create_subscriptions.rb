class CreateSubscriptions < ActiveRecord::Migration
  
  def change
    create_table :subscriptions do |t|

      t.references :plan
      t.references :user
      t.references :coupon
      t.decimal :application_fee_percent, precision: 8, scale: 2
      t.string :source
      t.integer :quantity, default: 1
      t.decimal :tax_percent, precision: 8, scale: 2
      t.integer :current_period_start
      t.integer :current_period_end
      t.integer :trial_start
      t.integer :trial_end
      t.string :status
      t.boolean :stripe_livemode
    

      t.timestamps null: false
    end

    add_foreign_key :subscriptions, :plans
    add_foreign_key :subscriptions, :users
    add_foreign_key :subscriptions, :coupons

    add_column :subscriptions, :team_id, :integer, index: true
    add_foreign_key :subscriptions, :users, column: :team_id
  end

end

