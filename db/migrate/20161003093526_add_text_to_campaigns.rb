class AddTextToCampaigns < ActiveRecord::Migration
  def up
   	add_column :campaigns, :text, :longtext
   	#remove_foreign_key :messages, :campaigns
   	remove_column :messages, :campaign_id, :integer
  end

  def down
    remove_column :campaigns, :text, :text
  end
end
