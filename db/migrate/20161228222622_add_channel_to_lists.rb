class AddChannelToLists < ActiveRecord::Migration
 def change
    add_column :lists, :channel, :integer, default: 0
  end
end
