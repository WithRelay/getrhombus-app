class AddStatusToPlans < ActiveRecord::Migration
  def change
    add_column :plans, :status, :integer, default: 1, after: :id
  end
end
