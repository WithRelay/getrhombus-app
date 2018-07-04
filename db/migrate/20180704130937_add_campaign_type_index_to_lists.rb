class AddCampaignTypeIndexToLists < ActiveRecord::Migration
  def change
  	add_index :lists, :campaign_type
  	add_index :lists, :list_type
  end
end
