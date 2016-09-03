class AddColumnsToHashtags < ActiveRecord::Migration
  def change
    add_column :hashtags, :interval, :string, before: :created_at
    add_column :hashtags, :interval_count, :integer, after: :interval
  end
end
