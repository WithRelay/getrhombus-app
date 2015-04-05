class ChangePhoneNumberInUsers < ActiveRecord::Migration
  def change
  	change_column :users, :phone_number, :string, :unique => true, :null => true
  end
end
