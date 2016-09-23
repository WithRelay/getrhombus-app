class AddMoreColumnToFbPage < ActiveRecord::Migration
  def change
    add_column :fb_pages, :page_name, :string
    add_column :fb_pages, :subscription_status, :boolean, default: false
  end
end
