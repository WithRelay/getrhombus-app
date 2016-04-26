class AddEnableTweetToHashtags < ActiveRecord::Migration
  def change
    add_column :hashtags, :enable_tweet, :boolean
  end
end
