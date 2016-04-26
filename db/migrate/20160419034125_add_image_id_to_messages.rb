class AddImageIdToMessages < ActiveRecord::Migration
  def change
    add_column :messages, :image_id, :integer
  end
end
