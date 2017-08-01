class AddActiveColOnFbPages < ActiveRecord::Migration
  def change
    add_column :fb_pages, :active, :boolean, default: true
  end
end
