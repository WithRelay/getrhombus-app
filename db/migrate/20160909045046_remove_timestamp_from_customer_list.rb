class RemoveTimestampFromCustomerList < ActiveRecord::Migration
  def change
    remove_column :customer_lists, :time, :timestamp
  end
end
