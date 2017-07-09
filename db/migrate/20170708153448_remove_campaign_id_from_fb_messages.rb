class RemoveCampaignIdFromFbMessages < ActiveRecord::Migration
  def change
    remove_foreign_key :fb_messages, column: :campaign_id
    remove_foreign_key :fb_messages, column: :fb_page_id
    remove_column :fb_messages, :campaign_id
  end
end
