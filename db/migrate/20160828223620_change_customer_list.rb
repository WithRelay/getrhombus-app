class ChangeCustomerList < ActiveRecord::Migration
  def change
  	remove_column :customer_lists, :list_references, :string
  end
end
