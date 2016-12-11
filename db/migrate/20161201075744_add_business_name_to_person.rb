class AddBusinessNameToPerson < ActiveRecord::Migration
  def up
    add_column :people, :business_name, :string
  end

  def down
    remove_column :people, :business_name, :string
  end
end
