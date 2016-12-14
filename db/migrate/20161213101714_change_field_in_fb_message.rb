class ChangeFieldInFbMessage < ActiveRecord::Migration
  def change
    remove_column :fb_messages, :page_id, :string
    add_column :fb_messages, :user_id, :integer
    add_column :fb_messages, :user_id_to, :integer
  end
end
