class RenameTypeFromHashtags < ActiveRecord::Migration
  def change
    rename_column :hashtags, :type, :tag_type
  end
end
