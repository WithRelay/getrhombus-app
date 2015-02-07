class ChangeRhombusandPhoneNumbersInUsers < ActiveRecord::Migration
  def change
  	change_column :users, :phone_number, :string
  	change_column :users, :rhombus_number, :string
  end
end
