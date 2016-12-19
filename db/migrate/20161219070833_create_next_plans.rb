class CreateNextPlans < ActiveRecord::Migration
  def change
    create_table :next_plans do |t|
      t.integer :user_id
      t.integer :plan_id
      t.boolean :status

      t.timestamps null: false
    end
    add_index :next_plans, :plan_id
  end
end
