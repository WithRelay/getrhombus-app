class UpdateColumnInFbCred < ActiveRecord::Migration
  def change
    add_column :fb_creds, :page_specific_id, :string
    rename_column :fb_creds, :u_id, :fb_id
  end
end
