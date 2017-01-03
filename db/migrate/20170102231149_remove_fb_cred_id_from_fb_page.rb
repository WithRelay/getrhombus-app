class RemoveFbCredIdFromFbPage < ActiveRecord::Migration
  def change
    remove_column :fb_pages, :fb_cred_id
  end
end
