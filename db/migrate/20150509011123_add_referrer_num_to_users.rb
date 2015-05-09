class AddReferrerNumToUsers < ActiveRecord::Migration
  def change
    add_column :users, :referrer_num, :string
    add_column :users, :subscription_type, :integer, :default => 0
    add_column :users, :url, :string
    add_column :users, :custom_welcome, :text
  end
end
