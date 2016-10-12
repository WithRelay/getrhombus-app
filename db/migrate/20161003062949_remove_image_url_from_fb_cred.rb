class RemoveImageUrlFromFbCred < ActiveRecord::Migration
  def change
  	remove_column :fb_creds, :image_url
  end
end
