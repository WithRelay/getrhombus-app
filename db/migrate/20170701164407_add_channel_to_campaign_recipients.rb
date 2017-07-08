class AddChannelToCampaignRecipients < ActiveRecord::Migration
  def change
    add_column :campaign_recipients, :channel, :integer, after: :list_id
  end
end
