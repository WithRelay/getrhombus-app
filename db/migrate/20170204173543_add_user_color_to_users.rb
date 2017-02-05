class AddUserColorToUsers < ActiveRecord::Migration
  def change
    add_column :users, :user_color, :string
  end
end
