class AddFieldInFbCred < ActiveRecord::Migration
  def up
    add_column :fb_creds, :profile_pic_url , :text
  end

  def down
    remove_column :fb_creds, :profile_pic_url, :text
  end
end
