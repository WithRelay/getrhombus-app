class RemoveListReferencesFromCustomerList < ActiveRecord::Migration
  def change
     remove_column :customer_lists, :list_references
  end
end
