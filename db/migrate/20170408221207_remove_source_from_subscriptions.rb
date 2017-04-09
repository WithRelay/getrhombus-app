class RemoveSourceFromSubscriptions < ActiveRecord::Migration
  def change
    remove_column :subscriptions, :source
  end
end
