class AddNumMediaToMessages < ActiveRecord::Migration
  def change
    add_column :messages, :num_media, :integer, default: 0, after: :num_segments
  end
end
