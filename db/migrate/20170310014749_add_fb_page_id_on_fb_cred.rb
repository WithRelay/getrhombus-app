class AddFbPageIdOnFbCred < ActiveRecord::Migration
  def change
    add_column :fb_creds, :fb_page_id, :integer, after: 'user_id'
  end
end
