class AddCampaignTypeToCampaigns < ActiveRecord::Migration
  def up
    add_column :campaigns, :campaign_type, :integer, default: 0
  end
  def down
    remove_column :campaigns, :campaign_type, :integer
  end
end
