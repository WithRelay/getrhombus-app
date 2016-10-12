class ChangeTextTypeInFbMessages < ActiveRecord::Migration
  def change
  	change_column :fb_messages, :text, :text
  end
end
