class RemoveListNameFromCustomerList < ActiveRecord::Migration
  def change
    remove_column :customer_lists, :list_name, :string
  end
end
