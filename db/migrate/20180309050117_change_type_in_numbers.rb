class ChangeTypeInNumbers < ActiveRecord::Migration
  def change
    rename_column :numbers, :type, :number_type
  end
end
