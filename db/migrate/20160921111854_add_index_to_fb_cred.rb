class AddIndexToFbCred < ActiveRecord::Migration
  def change
    add_index "fb_creds", ["id"], name: "index_fb_creds_on_id", unique: true
  end
end
