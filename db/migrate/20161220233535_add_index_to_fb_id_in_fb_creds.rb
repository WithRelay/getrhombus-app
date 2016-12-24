class AddIndexToFbIdInFbCreds < ActiveRecord::Migration
  def change
  	add_index :fb_creds, :fb_id
  end
end
