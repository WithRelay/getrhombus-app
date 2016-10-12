class RenameSaveRepliesToSavedReplies < ActiveRecord::Migration
  def change
  	remove_foreign_key :save_replies, :users
  	remove_reference :save_replies, :user, index: true
  	rename_table :save_replies, :saved_replies
    add_reference :saved_replies, :user, index: true
  end
end
