class RenameCustomerListToUserList < ActiveRecord::Migration
  def change
    class RenameCustomerListToUserList < ActiveRecord::Migration
      def change
       rename_table :customer_lists, :user_lists
       remove_index :user_lists, name: 'index_customer_lists_on_user_id'
       add_index :user_lists, :user_id
      end
    end
  end
end
