class RenameCustomerListToUserList < ActiveRecord::Migration
  def change
  	rename_table :customer_lists, :user_lists
  end
end
