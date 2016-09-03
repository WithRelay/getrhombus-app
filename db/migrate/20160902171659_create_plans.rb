class CreatePlans < ActiveRecord::Migration
  
  def change
    create_table :plans do |t|
            
      t.integer :amount
      t.string :currency
      t.string :interval
      t.integer :interval_count
      t.boolean :stripe_livemode
      t.string :name
      t.string :statement_descriptor, limit: 22
      t.integer :trial_period_days, default: 0

      t.references :hashtag
      t.integer :owner, default: 0, null: false 

      t.timestamps null: false
    end
  end

end
