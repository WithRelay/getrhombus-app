# added foreign key campaign id in message
class AddColumnCampaignIdToMessages < ActiveRecord::Migration
  def up
    add_column :messages, :campaign_id, :integer
  end
  def down
    remove_column :messages, :campaign_id, :integer
  end
end
