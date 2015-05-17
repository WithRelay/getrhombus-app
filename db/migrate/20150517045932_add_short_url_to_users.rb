class AddShortUrlToUsers < ActiveRecord::Migration
  def change
    add_column :users, :short_url, :string, :limit => 150, :null => true, :default => nil
  end
end
