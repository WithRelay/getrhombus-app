class RemoveIndexOnNameAndUserIdInPlans < ActiveRecord::Migration
  def change
  	remove_index :plans, name: 'index_plans_on_user_id_and_name'
  	add_index :plans, [:merchant_id, :name], unique: true
  end
end
