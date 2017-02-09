class AddHashtagIdToFbMessages < ActiveRecord::Migration
  def change
    add_column :fb_messages, :hashtag_id, :integer, index: true
  end
end
