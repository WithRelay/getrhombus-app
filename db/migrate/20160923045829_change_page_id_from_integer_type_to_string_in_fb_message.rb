class ChangePageIdFromIntegerTypeToStringInFbMessage < ActiveRecord::Migration
  def change
    change_column(:fb_messages, :page_id, :string)
  end
end
