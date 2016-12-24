class ChangeColumnInPlan < ActiveRecord::Migration
  def change
    remove_foreign_key :plans, column: :user_id   
    remove_column :plans, :user_id, :integer
    add_column :plans, :merchant_id, :integer
    add_column :plans, :customer_id, :integer
    add_index :plans, :merchant_id
    add_index :plans, :customer_id
  end
end
