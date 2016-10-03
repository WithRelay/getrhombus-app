class AddProfilePicUrlToFbCreds < ActiveRecord::Migration
  def change
    add_column :fb_creds, :profile_pic_url, :text
  end
end
