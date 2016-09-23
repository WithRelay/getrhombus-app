# added foreign key campaign id in message
class AddColumnCampaignIdToMessages < ActiveRecord::Migration
  def change
    add_column :messages, :campaign_id, :integer
    add_index :messages, :campaign_id
  end
end
