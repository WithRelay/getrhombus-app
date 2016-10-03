class AddFieldInFbCred < ActiveRecord::Migration
  def up
    # add_column :fb_creds, :profile_pic_url , :text
    # add_column :fb_creds, :page_specific_id, :string
  end

  def down     
    remove_column :fb_creds, :page_specific_id, :string
    remove_column :fb_creds, :profile_pic_url
  end
end
