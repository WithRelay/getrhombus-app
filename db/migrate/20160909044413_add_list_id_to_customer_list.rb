class AddListIdToCustomerList < ActiveRecord::Migration
  def change
    add_column :customer_lists, :list_id, :integer
  end
end
