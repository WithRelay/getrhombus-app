class AddColumnToTable < ActiveRecord::Migration
  def change
    remove_column :fb_creds, :image_url
    add_column :fb_creds, :time_zone, :string
    add_column :fb_creds, :gender, :string
    add_column :conversations, :created_at, :datetime
    add_column :conversations, :updated_at, :datetime
  end
end
