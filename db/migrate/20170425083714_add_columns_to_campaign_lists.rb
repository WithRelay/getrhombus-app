class AddColumnsToCampaignLists < ActiveRecord::Migration
  def change
    rename_column :campaign_lists, :customer_id, :merchant_customer_id
    add_column :campaign_lists, :merchant_contact_id, :integer
  end
end
