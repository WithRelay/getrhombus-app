class AddGenderToPeoples < ActiveRecord::Migration
  def up
    add_column :people, :gender, :string
  end

  def down
    remove_column :people, :gender, :string
  end
end
