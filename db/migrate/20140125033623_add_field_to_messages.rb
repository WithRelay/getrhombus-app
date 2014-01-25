class AddFieldToMessages < ActiveRecord::Migration
  def change
    add_column :messages, :messageId, :string
  end
end
