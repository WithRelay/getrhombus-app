class AddRnFriendlyNameToUser < ActiveRecord::Migration
  def change
    add_column :users, :rn_friendly_name, :string, after: :rhombus_number
  end
end
