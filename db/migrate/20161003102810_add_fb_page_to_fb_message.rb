class AddFbPageToFbMessage < ActiveRecord::Migration
  def change
    add_reference :fb_messages, :fb_page, index: true
    add_foreign_key :fb_messages, :fb_pages
  end
end
