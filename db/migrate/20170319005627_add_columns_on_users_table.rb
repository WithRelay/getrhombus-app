class AddColumnsOnUsersTable < ActiveRecord::Migration
  def change
  	add_column :users, :rate_percent, :string, default: '2.9'
  	add_column :users, :rate_cents, :integer, default: 30
  end
end
