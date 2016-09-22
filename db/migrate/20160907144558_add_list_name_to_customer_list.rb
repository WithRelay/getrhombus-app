class AddListNameToCustomerList < ActiveRecord::Migration
  def change
    add_column :customer_lists, :list_name, :string
  end
end
