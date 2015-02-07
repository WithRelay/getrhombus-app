class ChangePhoneNumberInUsers < ActiveRecord::Migration
  def change
  	change_column :users, :phone_number, :string, :unique => true, :null => true
  	#add_column :users, :phone_number, :string, :unique => true
  	#change_column :users, :rhombus_number, :string, :unique => true
  end
end
