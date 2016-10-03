class AddUserIdToFbCred < ActiveRecord::Migration
  def change
    add_column :fb_creds, :user_id, :integer
    add_index :fb_creds, :user_id, name: "index_fb_creds_on_user_id", unique: true
  end
end
