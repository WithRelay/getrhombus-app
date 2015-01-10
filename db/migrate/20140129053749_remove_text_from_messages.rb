class RemoveTextFromMessages < ActiveRecord::Migration
  def change
  	remove_column :messages, :text
  end
end
