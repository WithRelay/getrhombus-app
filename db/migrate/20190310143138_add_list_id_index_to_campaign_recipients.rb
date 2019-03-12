class AddListIdIndexToCampaignRecipients < ActiveRecord::Migration
  def change
    add_index :campaign_recipients, :list_id
  end
end
