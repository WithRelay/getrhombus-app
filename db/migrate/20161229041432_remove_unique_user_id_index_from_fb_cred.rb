class RemoveUniqueUserIdIndexFromFbCred < ActiveRecord::Migration
  def change
    remove_index :fb_creds, :user_id
    add_index :fb_creds, :user_id
  end
end
