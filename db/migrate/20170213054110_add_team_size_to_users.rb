class AddTeamSizeToUsers < ActiveRecord::Migration
  def change
    add_column :users, :team_size, :string
  end
end
