class ChangeMessageIdFromIntegerTypeToStringInFbMessage < ActiveRecord::Migration
  def change
    change_column(:fb_messages, :message_id, :string)
  end
end