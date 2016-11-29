class ChangeRoleInPeopleToEnum < ActiveRecord::Migration
  def change
  	change_column :people, :role, :integer
  end
end
