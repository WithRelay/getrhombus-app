class ChangePhoneAndRhombusNumbersIndexInUsers < ActiveRecord::Migration
  def change
  	change_column :users, :phone_number, :string, :unique => true, :null => true
  	change_column :users, :rhombus_number, :string, :unique => true, :null => true
  	remove_index :users, :phone_number
  	add_index :users, :phone_number, :unique => true
  	remove_index :users, :rhombus_number
  	add_index :users, :rhombus_number, :unique => true
  end
end
