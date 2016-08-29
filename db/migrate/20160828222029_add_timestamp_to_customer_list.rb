class AddTimestampToCustomerList < ActiveRecord::Migration
  def change
    add_column :customer_lists, :time, :timestamp
  end
end
