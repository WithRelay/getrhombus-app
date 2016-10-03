class FixMigration < ActiveRecord::Migration
  def change
    add_column :fb_pages, :fb_cred_id, :integer
  end
end
