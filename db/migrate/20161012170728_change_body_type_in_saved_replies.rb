class ChangeBodyTypeInSavedReplies < ActiveRecord::Migration
  def change
  	change_column :saved_replies, :body, :text
  end
end
