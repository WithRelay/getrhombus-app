class AddStatusToHashtags < ActiveRecord::Migration
  def change
    add_column :hashtags, :status, :integer, default: 0, after: :tag_type
  end
end
