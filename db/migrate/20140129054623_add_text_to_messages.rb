class AddTextToMessages < ActiveRecord::Migration
  def change
    add_column :messages, :text, :string
    remove_column :messages, :type
  end
end
